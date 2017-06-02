param (
    [Parameter(Mandatory=$True)] [string]$LocalGWName,
    [Parameter(Mandatory=$True)] [string]$ResourceGroupName,
    [Parameter(Mandatory=$True)] [string]$LocalEndpoint
    )

# example:
#
# .\change-lgw-ipaddr.ps1 -LocalGWName cljung-home-gw -ResourceGroupName cljungrgwe01 -LocalEndpoint mydomain.com
#

# ----------------------------------------------------------------------------
function ResolvetOutgoingIpAddr($hostname) {	
	# nslookup of a service we have in the web layer
    $nsres = nslookup $hostname
	# grab the "Address: x.y.z.w" line. Search from end since the first address lines may be DNS servers ip addr
    for ($i=$nsres.SyncRoot.Count-1; $i -ge 0; $i--)
    {
	    $line = $nsres.SyncRoot[$i]
		if ( $line -Match "Address:") {
			return $line.Split(":")[1].Replace(" ", "")
		}
	}
	# exit script since we can not continue
	Write-Error "Cloud not resolve ip address for " + $hostname
	exit 1
}

# ----------------------------------------------------------------------------
$ipaddr = ResolvetOutgoingIpAddr $LocalEndpoint

Write-Host "$LocalEndpoint is currently $ipaddr"

$lgw = Get-AzureRmLocalNetworkGateway -Name $LocalGWName -ResourceGroupName $ResourceGroupName
Write-Host "$LocalGWName is currently $($lgw.GatewayIpAddress)"

if ( $lgw.GatewayIpAddress -ne $ipaddr ) {
    Write-Host "Updating..."
    $lgw.GatewayIpAddress = $ipaddr
    $lgw | Set-AzureRmLocalNetworkGateway
}
