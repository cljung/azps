param(
 [Parameter(Mandatory=$False)] [string] $ResourceGroupName = "",
 [Parameter(Mandatory=$False)] [string] $Location = "",
 [Parameter(Mandatory=$False)] [string] $VirtualNetworkName = "",
 [Parameter(Mandatory=$False)] [string] $SubnetName = "",
 [Parameter(Mandatory=$False)] [string] $VmName = "",
 [Parameter(Mandatory=$False)] [string] $VMSize = "",
 [Parameter(Mandatory=$False)] [string] $OsType = "",
 [Parameter(Mandatory=$False)] [string] $CustomScriptUrl = "",
 [Parameter(Mandatory=$False)] [string] $StorageAccountName = "",
 [Parameter(Mandatory=$False)] [string] $SourceImageUrl = "", 
 [Parameter(Mandatory=$False)] [string] $OsDisk = "",  
 [Parameter(Mandatory=$False)] [bool] $BootDiagnostics = $false,
 [Parameter(Mandatory=$False)] [string] $ConfigFile = ""
 )
<#
.\arm\vm\create-vm-existing.ps1 -ResourceGroupName "cljungrgwe01" -VmName "cljungws1601" -ConfigFile ".\cljunghost01-existing.json"
#>

# #################################################################################################################
# Load config file
# #################################################################################################################
$PipName = "$vmName-pip"
$NicName = "$vmName-nic"

if ( Test-Path $ConfigFile ) {
    $cfg = (Get-Content -Raw -Path $ConfigFile | ConvertFrom-Json)
    if ( $ResourceGroupName -eq "") { $ResourceGroupName = $cfg.ResourceGroupName }
    if ( $Location -eq "") { $Location = $cfg.Location }
    if ( $VirtualNetworkName -eq "") { $VirtualNetworkName = $cfg.VirtualNetworkName }
    if ( $SubnetName -eq "") { $SubnetName = $cfg.SubnetName }
    if ( $VmName -eq "") { $VmName = $cfg.VmName }
    if ( $VMSize -eq "") { $VMSize = $cfg.VMSize }
    if ( $OsType -eq "") { $OsType = $cfg.OsType }
    if ( $StorageAccountName -eq "") { $StorageAccountName = $cfg.StorageAccountName }    
    if ( $SourceImageUrl -eq "") { $SourceImageUrl = $cfg.SourceImageUrl }        
    if ( $OsDisk -eq "") { $OsDisk = $cfg.OsDisk }        
    if ( $CustomScriptUrl -eq "") { $CustomScriptUrl = $cfg.CustomScriptUrl }
    if ( $cfg.NicName -ne $null ) { $NicName = $cfg.NicName }
    if ( $cfg.PublicIpName -ne $null ) { $PipName = $cfg.PublicIpName }
}

# #################################################################################################################
# get real url of storage account
# #################################################################################################################
#$ctx = Get-AzureRmContext
#$destinationVhd = "http://$StorageAccountName.blob.$($ctx.Environment.StorageEndpointSuffix)/vhds/"
#write-host "Storage:" $destinationVhd

# #################################################################################################################
# copy the source vhd image if specified (else we create the VM pointing straight to the OsDiskUrl)
# #################################################################################################################
if ( $SourceImageUrl -ne "" ) {
    $OsDiskUrl = "$destinationVhd$vmName-osdisk.vhd"
    write-host "Copying SourceImage VHD $SourceImageUrl"
    $stgacct = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
    Start-AzureStorageBlobCopy -AbsoluteUri $SourceImageUrl -DestContainer "vhds" -DestBlob "$vmName-osdisk.vhd" -DestContext $stgacct.Context    
}

# #################################################################################################################
# dig up VNet/subnet to use
# #################################################################################################################
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName -Name $VirtualNetworkName
$subnet = $vnet.Subnets | where-object {$_.Name -eq $SubnetName}
write-host "VNet:" $vnet.Name ", Subnet:" $subnet.Name "" $subnet.AddressPrefix

# #################################################################################################################
# get or create the Public IP Address and NIC
# #################################################################################################################
if ( $PipName -eq "" ) {
    write-host "No Public IP Address"
} else {
    $pip = Get-AzureRmPublicIpAddress -Name $PipName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
    if ( $pip -eq $null ) {
        write-host "Creating new Public IP Address" $PipName
        $pip = New-AzureRmPublicIpAddress -Name $PipName -ResourceGroupName $ResourceGroupName `
                                            -Location $location -AllocationMethod Dynamic
    } else {
        write-host "Using existing Public IP Address" $PipName
    }
}

$nic = Get-AzureRmNetworkInterface -Name $NicName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
if ( $nic -eq $null ) {
    write-host "Creating new NIC" $NicName    
    $nic = New-AzureRmNetworkInterface -Name $NicName -ResourceGroupName $resourceGroupName `
                                    -Location $location -SubnetId $subnet.Id -PublicIpAddressId $pip.Id
} else {
    write-host "Using existing NIC" $NicName   $nic.IpConfigurations.PrivateIpAddress 
}

# #################################################################################################################
# set the basic VM config stuff
# #################################################################################################################

write-host "VMSize:" $VMSize 
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $VMSize
write-host "OS: $OsType"

# standard disk
if ( $OsDisk.EndsWith(".vhd") ) {
    if ( $OsType -eq "Windows" ) {
        $vmConfig = Set-AzureRmVMOSDisk -VM $vmConfig -Name "$vmName-osdisk" -VhdUri $OsDisk `
                        -CreateOption Attach -Caching ReadWrite -Windows
    }                                    
    if ( $OsType -eq "Linux" ) {
        $vmConfig = Set-AzureRmVMOSDisk -VM $vmConfig -Name "$vmName-osdisk" -VhdUri $OsDisk `
                        -CreateOption Attach -Caching ReadWrite -Linux
    }                                    
} 
# managed disk
if ( $OsDisk.Contains("Microsoft.Compute/disks/") ) {
    if ( $OsType -eq "Windows" ) {
        $vmConfig = Set-AzureRmVMOSDisk -VM $vmConfig -ManagedDiskId $OsDisk `
                        -CreateOption Attach -Caching ReadWrite -Windows
    }                                    
    if ( $OsType -eq "Linux" ) {
        $vmConfig = Set-AzureRmVMOSDisk -VM $vmConfig -ManagedDiskId $OsDisk `
                        -CreateOption Attach -Caching ReadWrite -Linux
    }                                    
}

$vmConfig = Add-AzureRmVMNetworkInterface -VM $vmConfig -Id $nic.Id
if ( $BootDiagnostics -eq $false ) {
    write-host "Disabling boot diagnostics"
    $vmConfig = Set-AzureRmVMBootDiagnostics -VM $vmConfig -Disable
}
                                
# #################################################################################################################
# add the data disks if specified
# #################################################################################################################
if ( $OsDisk.EndsWith(".vhd") ) {
    foreach( $dd in $cfg.DataDisks) {
        write-host "Attaching Standard DataDisk" $dd.Name "to" $dd.Vhd.Uri
        $vmConfig = Add-AzureRmVMDataDisk -VM $vmConfig -LUN $dd.Lun -Name $dd.Name -DiskSizeinGB $dd.DiskSizeGB `
                        -Caching $dd.Caching -CreateOption Attach -VhdUri $dd.Vhd.Uri  
    }
} else {
    foreach( $dd in $cfg.DataDisks) {
        write-host "Attaching Managed DataDisk" $dd.Name 
        $vmConfig = Add-AzureRmVMDataDisk -VM $vmConfig -LUN $dd.Lun -Name $dd.Name -DiskSizeinGB $dd.DiskSizeGB `
                        -Caching $dd.Caching -CreateOption Attach -ManagedDiskId $dd.ManagedDisk.Id  
    }
}
# #################################################################################################################
# create the VM
# #################################################################################################################
write-host (get-date).ToLongTimeString() "- Create VM initiated..."

$vm = New-AzureRmVM -VM $vmConfig -Location $location -ResourceGroupName $resourceGroupName

write-host (get-date).ToLongTimeString() "- Create VM completed"

if ( $PipName -ne "" ) {
    $pip = Get-AzureRmPublicIpAddress -Name $PipName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
    write-host "Public ip address" $pip.IpAddress
}

# #################################################################################################################
# Run the custom script extension if specified
# #################################################################################################################
if ( $CustomScriptUrl -ne "" ) {
    write-host (get-date).ToLongTimeString() "- Custom Script Extension started..."
    write-host $CustomScriptUrl
    $p = $CustomScriptUrl.Split("/")
    $scriptFile = $p[$p.Length-1]
    $fileUris = @($CustomScriptUrl)

    Set-AzureRmVMCustomScriptExtension -ResourceGroupName $resourceGroupName `
            -VMName $vmName -Location $Location `
            -Name $scriptFile -FileUri $fileUris -Run $scriptFile `
            -WarningAction SilentlyContinue

    write-host (get-date).ToLongTimeString() "- Custom Script Extension ended"
}
