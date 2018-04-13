param(
 [Parameter(Mandatory=$true)] [string] $ResourceGroupName = "",
 [Parameter(Mandatory=$true)] [string] $VmName = "",
 [Parameter(Mandatory=$False)] [string] $ConfigFile = ""
 )
<#
.\arm\vm\save-vm-to-json.ps1 -ResourceGroupName "cljungrgwe01" -VmName "cljungws1601" $ConfigFile ".\cljungws1601-existing.json" 
#>

# #################################################################################################################
# create the VM
# #################################################################################################################
write-host (get-date).ToLongTimeString() "- Getting VM details..."

$vm = get-azurermvm -ResourceGroupName $resourceGroupName -name $VmName
if ( $vm.OSProfile.LinuxConfiguration -eq $null ) { $OsType = "Windows" } else { $OsType = "Linux" }
$nicid = $vm.NetworkProfile.NetworkInterfaces.id.Split("/")
$nic = Get-AzureRmNetworkInterface -ResourceGroupName $nicid[4] -Name $nicid[8]
$vnet = $nic.IpConfigurations[0].Subnet.Id.Split("/")
if ( $nic.IpConfigurations[0].PublicIpAddress -ne $null ) {
    $PipName = $nic.IpConfigurations[0].PublicIpAddress.Id.Split("/")[8]
} else {
    $PipName = ""
}
write-host (get-date).ToLongTimeString() "- done"

$osDisk = ""
$StorageAccountName = ""

if ( $vm.StorageProfile.OsDisk.Vhd -ne $null ) {
    $osDisk = $($vm.StorageProfile.OsDisk.Vhd.Uri | ConvertTo-json)
    $StorageAccountName = $($vm.StorageProfile.OsDisk.Vhd.Uri.Split("/")[2].Split(".")[0])
} 
if ( $vm.StorageProfile.OsDisk.ManagedDisk -ne $null ) {
    $osDisk = $vm.StorageProfile.OsDisk.ManagedDisk.Id | ConvertTo-json
}
# write out json
$json = "{`
    ""ResourceGroupName"": ""$($vm.ResourceGroupName)"",`
    ""Location"": ""$($vm.Location)"",`
    ""VmName"": ""$($vm.Name)"",`
    ""BootDiagnostics"": false,`
    ""OsType"": ""$OsType"",`
    ""ImageReference"": $($vm.StorageProfile.ImageReference | ConvertTo-Json),`
    ""StorageAccountName"": ""$StorageAccountName"",`
    ""SourceImageUrl"": """",`
    ""OsDisk"": $osDisk,`
    ""DataDisks"": $($vm.StorageProfile.DataDisks | ConvertTo-Json),`
    ""VMSize"": ""$($vm.HardwareProfile.VmSize)"",`
    ""NicName"": ""$($nic.Name)"",`
    ""PublicIpName"": ""$PipName"",`
    ""VirtualNetworkName"": ""$($vnet[8])"",`
    ""SubnetName"": ""$($vnet[10])"",`
    ""CustomScriptUrl"": """"`
`n}"

if ( $ConfigFile -ne "" ) {
    set-content -Path $ConfigFile -Value $json
} else {
    write-host $json
}
