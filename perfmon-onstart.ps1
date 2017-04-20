Param(
   [Parameter(Mandatory=$False)][int]$SampleInterval = 5,
   [Parameter(Mandatory=$False)][int]$MaxSamples = 100,
   [Parameter(Mandatory=$False)][string]$ArchivePath = "\\192.168.156.208\delat\perfmon\"
)
mkdir c:\tools
$outfile="c:\tools\run-perfmon.ps1"

$buf = @"
`$CtrList = @( "\Process(*)\% Processor Time" )
`$perflogfile = "perflog_`$(`$env:computername)_`$(Get-Date -format 'yyyyMMdd_HHmmss').csv"
`$perflogpath = "`$(`$env:temp)\`$perflogfile"
Get-Counter -Counter `$CtrList -SampleInterval $SampleInterval -MaxSamples $MaxSamples | Export-Counter -Path `$perflogpath -FileFormat CSV -Force
Copy-Item `$perflogpath $ArchivePath
"@

write-output $buf > $outfile

schtasks /CREATE /TN "Perfmon onboot" /SC ONSTART /RL HIGHEST /S $env:computername /RU SYSTEM /TR "powershell -ExecutionPolicy Unrestricted -File $outfile" /F 
