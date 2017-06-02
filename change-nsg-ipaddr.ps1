param (
    [Parameter(Mandatory=$True)] [string]$NSGName,
    [Parameter(Mandatory=$True)] [string]$ResourceGroupName,
    [Parameter(Mandatory=$False)] [string]$SecurityRuleName = "allow-all-from-temp-ip",
    [Parameter(Mandatory=$False)] [string]$Operation = "update" # list/show
    )

# example:
#
# .\change-nsg-ipaddr.ps1 -NSGName cljungubu16sf-nsg -ResourceGroupName cljungrgwe01
#

# ----------------------------------------------------------------------------
$nsg = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name $NSGName

# ----------------------------------------------------------------------------
function UpdateNSGRules() {
    $acct = Get-AzureRmContext
    $user = $acct.Account.Id

    $resp = Invoke-RestMethod "http://ipinfo.io"
    Write-Host "Current ip addr $($resp.ip) via provider $($resp.org)"

    $sourceAddrPrefix = "$($resp.ip)/32"
    $description = "allow all inbound from temp ip $($resp.ip), provider $($resp.org). Set by $user at $(Get-Date -format 's')"

    $rule = ($nsg | Get-AzureRmNetworkSecurityRuleConfig -Name $SecurityRuleName -ErrorAction SilentlyContinue)
    if ($rule -eq $null) {
    $prio = [int]($nsg.SecurityRules[$nsg.SecurityRules.Count-1].Priority)
    $prio += 10
    Write-Host "Adding $SecurityRuleName rule to allow $sourceAddrPrefix with priority $prio"
    $ret = ($nsg | Add-AzureRmNetworkSecurityRuleConfig -Name $SecurityRuleName `
                    -SourceAddressPrefix $sourceAddrPrefix  -SourcePortRange "*" `
                    -DestinationAddressPrefix "*" -DestinationPortRange "*" `
                    -Protocol "*" -Direction "Inbound" -Access "Allow" `
                    -Priority $prio -Description $description)
    } else {
        Write-Host "Updating $SecurityRuleName rule to allow $sourceAddrPrefix"
        $ret = ($nsg | Set-AzureRmNetworkSecurityRuleConfig -Name $SecurityRuleName `
                        -SourceAddressPrefix $sourceAddrPrefix  -SourcePortRange "*" `
                        -DestinationAddressPrefix "*" -DestinationPortRange "*" `
                        -Protocol "*" -Direction "Inbound" -Access "Allow" `
                        -Priority $rule.Priority -Description $description)
    }
    Write-Host "Saving to Azure..."
    $ret = ($nsg | Set-AzureRmNetworkSecurityGroup)
}

# ----------------------------------------------------------------------------
function ListNSGRules() {

    $nsg.SecurityRules | select Priority, Name, Direction, SourceAddressPrefix, DestinationAddressPrefix, Access, Protocol, SourcePortRange, Description
}
# ----------------------------------------------------------------------------
switch ( $Operation.ToLower() )
{
	"show" { ListNSGRules }
	"list" { ListNSGRules }
    "update" { UpdateNSGRules }
	default { Write-Host "Operation must be list, show or update" }
}

