param (
    [Parameter(Mandatory=$false)] [string]$SubscriptionName = ""
    )

if ( $SubscriptionName -eq "" ) {
	$sub = get-azurermcontext
} else {
	$sub = Select-AzureRmSubscription -SubscriptionName $SubscriptionName 
}

$userid = $sub.Account.Id
$subName = $sub.Subscription.Name

$host.ui.RawUI.WindowTitle = "PS Azure - $userid - $subName"

