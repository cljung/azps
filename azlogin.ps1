param (
    [Parameter(Mandatory=$False)] [string]$EnvironmentName = "AzureCloud",
    [Parameter(Mandatory=$False)] [bool]$Dbg = $False
    )

# EnvironmentName may be AzureCloud, AzureGermanCloud, AzureChinaCloud, AzureUSGovernment
# complete list in Get-AzureRmEnvironment

if ( $EnvironmentName -imatch "German" -or $EnvironmentName -ieq "de") {
    $EnvironmentName = "AzureGermanCloud"
}
if ( $EnvironmentName -imatch "China" -or $EnvironmentName -ieq "cn") {
    $EnvironmentName = "AzureChinaCloud"
}
if ( $EnvironmentName -imatch "USGov" -or $EnvironmentName -ieq "usgov") {
    $EnvironmentName = "AzureUSGovernment"
}
write-host $EnvironmentName
$startTime = Get-Date

if ( $Dbg -eq $True ) {
  $login = Login-AzureRmAccount -EnvironmentName $EnvironmentName -debug
} else {
  $login = Login-AzureRmAccount -EnvironmentName $EnvironmentName
}

$finishTime = Get-Date
$TotalTime = ($finishTime - $startTime).TotalSeconds
Write-Output "Time: $TotalTime sec(s)"        

$userid = $login.Context.Account.Id
$subName = $login.Context.Subscription.Name

#write-output "PS Azure - $($login.SubscriptionName) - $($login.Account)"
$host.ui.RawUI.WindowTitle = "PS Azure - $userid - $subName"

if ( $EnvironmentName -ne "AzureCloud ") {
    Get-AzureRmEnvironment -Name $EnvironmentName
}