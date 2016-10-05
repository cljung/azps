Param(
   [Parameter(Mandatory=$True)][string]$WebSite = "",   # existing Azure AppService WebApp site
   [Parameter(Mandatory=$True)][string]$Path = "",      # path containing .\webapps\blabla1.war file. Note must be parent of webapps folder
   [Parameter(Mandatory=$True)][string]$ZipFile = ""    # name of zip file to zip .\webapps\blabla1.war file to
)

# ---------------------------------------------------------------------------
# compress the target path
# ---------------------------------------------------------------------------
$Path = [System.IO.Path]::GetFullPath((Join-Path $pwd $Path))
$ZipFile = [System.IO.Path]::GetFullPath((Join-Path $pwd $ZipFile))

if ( Test-Path $ZipFile ) {
	Remove-Item $ZipFile
}
write-host "zipping $Path to $ZipFile"
Add-Type -Assembly System.IO.Compression.FileSystem
$compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
[System.IO.Compression.ZipFile]::CreateFromDirectory($Path, $ZipFile, $compressionLevel, $False)
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
# set the parameters
$setParams = ""

# run msdeploy.exe
$p = start-process -filepath $msdeploy -wait -NoNewWindow  `
	-argumentlist "-source:package='$zipfile' -dest:auto,computerName='$publishingUrl',UserName='$publishingUid',Password='$publishingPwd',authtype='Basic',includeAcls='False' -verb:sync -disableLink:AppPoolExtension -disableLink:ContentExtension -disableLink:CertificateExtension -enableRule:DoNotDeleteRule -allowUntrusted -retryAttempts:2 $setParams" 
