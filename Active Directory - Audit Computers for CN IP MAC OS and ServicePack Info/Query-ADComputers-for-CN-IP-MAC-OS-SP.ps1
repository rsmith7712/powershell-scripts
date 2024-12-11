<#
.SUMMARY
    Use PowerShell and the AD module 
    to get a listing of computers and IP addresses
#>

$results = Get-ADComputer -Filter * -Properties ipv4Address, MacAddress, OperatingSystem, OperatingSystemServicePack | Format-List name, ipv4*, mac*, oper*
$results | Out-File C:\temp\AD-Systems-n-IPs.txt
#$results | Export-Csv C:\temp\AD-Systems-n-IPs.csv -NoTypeInformation