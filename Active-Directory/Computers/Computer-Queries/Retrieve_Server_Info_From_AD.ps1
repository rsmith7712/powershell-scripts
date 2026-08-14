#Connect to Active Directory
Import-Module ActiveDirectory

#Retrieve server systems from Active Directory
Get-ADComputer -Filter {OperatingSystem -like "*windows*server*"} -Properties DNSHostName, OperatingSystem,IPv4Address | Sort-Object DNSHostname

#Export the List to a CSV File
Get-ADComputer -Filter {OperatingSystem -like "*windows*server*"} -Properties DNSHostName, OperatingSystem,IPv4Address | Sort-Object DNSHostname | Export-Csv -Path "C:\tmp\ADServers.csv" -NoTypeInformation
