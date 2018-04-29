$ZoneName = "fawltytowers2.com"
$RgName = "cljungrgne01"

# et current break out ip address
$resp = Invoke-RestMethod "http://ipinfo.io"

$dnsrec = Get-AzureRmDnsRecordSet -ZoneName $ZoneName -ResourceGroupName $RgName -Name "Home" -RecordType "A"

# remove current A record
$dnsrec.Records.Remove($dnsrec.Records[0])

# add new a record
Add-AzureRmDnsRecordConfig -RecordSet $dnsrec -Ipv4Address $resp.ip

# update the Azure DNS
Set-AzureRmDnsRecordSet -RecordSet $dnsrec
