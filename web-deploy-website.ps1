Param(
   [Parameter(Mandatory=$True)][string]$WebSite = "",   # existing Azure AppService WebApp site
   [Parameter(Mandatory=$True)][string]$ZipFile = ""    # name of Web Deploy Package zip file
)

# ---------------------------------------------------------------------------
# get the Azure Website 
# ---------------------------------------------------------------------------
$ws = Get-AzureWebsite -Name $WebSite -ErrorAction Continue
if ( $ws -eq $null ) {
	write-host "Azure WebSite $WebSite does not exist!"
	exit 1
}

# get the web publish url and the uid/pwd
$publishingUid = $ws.PublishingUsername
$publishingPwd = $ws.PublishingPassword
$publishingUrl = ""
foreach( $hostname in $ws.EnabledHostNames) {
	if ( $hostname -match ".scm.") {
		$publishingUrl = "https://" + $hostname + ":443/msdeploy.axd?site=" + $WebSite
	}
}
# ---------------------------------------------------------------------------
# get where msdeploy is located and deploy the app
# ---------------------------------------------------------------------------
$msdeploy="C:\Program Files (x86)\IIS\Microsoft Web Deploy V3\msdeploy.exe"
$rkey = get-itemproperty -path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IIS Extensions\MSDeploy\3" -Name InstallPath
if ($rkey -ne $null ) {
	$msdeploy = $rkey.InstallPath  + "msdeploy.exe"
}

# ---------------------------------------------------------------------------
# run msdeploy to deploy the zipfile to Azure
# ---------------------------------------------------------------------------
write-host "Deploying package: $ZipFile"
write-host "To: $publishingUrl"
# set the parameters
$setParams = "-setParam:name=`"IIS Web Application Name`",value=`"" + $WebSite + "`" "

# run msdeploy.exe
$p = start-process -filepath $msdeploy -wait -NoNewWindow  `
	-argumentlist "-source:package='$zipfile' -dest:auto,computerName='$publishingUrl',UserName='$publishingUid',Password='$publishingPwd',authtype='Basic',includeAcls='False' -verb:sync -disableLink:AppPoolExtension -disableLink:ContentExtension -disableLink:CertificateExtension -enableRule:DoNotDeleteRule -allowUntrusted -trace -retryAttempts:2 $setParams" 
