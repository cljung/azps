<#
 .SYNOPSIS
    VIrtual Network Gateway tree

 .DESCRIPTION
    Traverses all accessible subscriptions to search for VPN Gateways and peered networks
#>


# get a VNet in a specific subscription
function GetVirtualNetworkInSubscription( $currSubscriptionId, $subscriptionId, $resourceGroupName, $resourceName ) {
    if ( $currSubscriptionId -ne $subscriptionId) {
        Select-AzureRmSubscription -SubscriptionId $subscriptionId | out-null    
    }
    $vnetS = Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName -Name $resourceName
    if ( $currSubscriptionId -ne $subscriptionId) {
        Select-AzureRmSubscription -SubscriptionId $currSubscriptionId | out-null  
    }
    return $vnetS  
}

$count = 0
write-host (get-date).ToLongTimeString() "- Started"

$sublist = Get-AzureRmSubscription | where-object {$_.State -eq "Enabled"} | Sort-Object | Select-Object Name, Id, TenantId
foreach( $sub in $sublist) {
    Select-AzureRmSubscription -SubscriptionId $sub.Id | out-null
    $count += 1
    $first = $true
    $vnets = Get-AzureRmVirtualNetwork
    if ( $vnets -ne $null ) {
        foreach( $vnet in $vnets ) {
            # GatewaySubnet is a sign that VNet may have a VGW
            $gwsubnet = ($vnet.Subnets | where { $_.Name -eq "GatewaySubnet" })
            if ( $gwsubnet -ne $null -and $gwsubnet.IpConfigurations -ne $null ) {
                $gwparts = $gwsubnet.IpConfigurations[0].Id.Split("/")
                $vgw = Get-AzureRmVirtualNetworkGateway -ResourceGroupName $gwparts[4] -ResourceName $gwparts[8]
                $vgwparts = $vgw.IpConfigurations[0].PublicIpAddress.Id.Split("/")
                $pip = Get-AzureRmPublicIpAddress -ResourceGroupName $vgwparts[4] -ResourceName $vgwparts[8]
                $vgwconn = Get-AzureRmVirtualNetworkGatewayConnection -ResourceGroupName $gwparts[4]
                # if the VGW is connected, go deeper
                if ( $vgwconn -ne $null ) {
                    if ( $first -eq $true ) {
                        write-host $sub.Name $sub.Id
                        $first = $false
                    }
                    $vgwlparts = $vgwconn[0].LocalNetworkGateway2.Id.Split("/")
                    $lgw = Get-AzureRmLocalNetworkGateway -ResourceGroupName $vgwlparts[4] -ResourceName $vgwlparts[8]
                    write-host "VGW " $gwparts[8] $gwsubnet.AddressPrefix $vgw.VpnType $vgw.Sku[0].Name $pip.IpAddress "->" $vgwconn[0].Name $lgw.Name $lgw.GatewayIpAddress $lgw.LocalNetworkAddressSpace[0].AddressPrefixes
                    write-host "  VNet" $vnet.Name $vnet.AddressSpace.AddressPrefixes $vnet.Location

                    # list VNet peerings
                    if ( $vnet.VirtualNetworkPeerings -ne $null ) { 
                        foreach( $peer in $vnet.VirtualNetworkPeerings ) {
                            $peerparts = $peer.RemoteVirtualNetwork.Id.Split("/")
                            $subP = ($sublist | where-object {$_.Id -eq $peerparts[2] } | select-object Name)
                            $vnetS = GetVirtualNetworkInSubscription $sub.Id $peerparts[2] $peerparts[4] $peerparts[8]
                            write-host "   Peer" $peer.Name $peer.PeeringState "->" $peerparts[8] "in" $subP.Name $vnetS.AddressSpace.AddressPrefixes
                        }
                    }             
                }
            }            
        }
    }
}

write-host (get-date).ToLongTimeString() "- Finished." $count "subscriptions checked"