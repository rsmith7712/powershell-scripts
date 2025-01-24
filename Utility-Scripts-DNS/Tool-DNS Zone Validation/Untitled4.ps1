$results = Get-DnsServerZone | % {
    $zone = $_.zonename
    Get-DnsServerResourceRecord $zone | select @{n='ZoneName';e={$zone}}, HostName, timestamp, RecordType, @{n='RecordData';e={if ($_.RecordData.IPv4Address.IPAddressToString) {$_.RecordData.IPv4Address.IPAddressToString} else {$_.RecordData.NameServer.ToUpper()}}}
}

$results | Export-Csv -NoTypeInformation C:\temp\DNSRecords.csv -Append