#Get DNSHostName, OS, OS Ver, IPv4

#Get-ADComputer -filter * -property * | select DNSHostName, OperatingSystem, OperatingSystemVersion, IPv4Address | Export-Csv C:\temp\ps_osResultsQuery.csv -NoTypeInformation

Get-ADComputer -filter * -property * | select DNSHostName, OperatingSystem, OperatingSystemVersion, IPv4Address | fl