
# Load the Microsoft Active Directory Module
Import-Module ActiveDirectory

# Get a list of computers that have WIN7 in their name
Get-ADComputer -Filter { Name -Like "*Win*7*" } | ForEach-Object {$_.Name}
Get-ADComputer -Filter { (OperatingSystem -Like "Windows 7 Pro") -or (OperatingSystem -Like "Windows 7 Enterprise") } #-Searchbase "distinguishedName of OU"
Get-ADComputer -Filter { (OperatingSystem -Like "Windows 10 Pro") -or (OperatingSystem -Like "Windows 10 Enterprise") } #-Searchbase "distinguishedName of OU"
Get-ADComputer -Filter { (OperatingSystem -Like "Windows 11 Pro") -or (OperatingSystem -Like "Windows 11 Enterprise") } #-Searchbase "OU=Corp,DC=Symetrix,DC=com"

# Get a list of all computer names
Get-ADComputer -Filter * | ForEach-Object {$_.Name}

# Get a list of fully qualified host names
Get-ADComputer -Filter * | ForEach-Object {$_.DNSHostName}

Clear-Host

# Query and display all Windows devices; List by Name, IPv4Address, OperatingSystem
Get-ADComputer -Filter * -Properties ipv4Address, OperatingSystem | Format-List Name, ipv4*, OperatingSystem | Out-File C:\Results\All-Windows-Devices.txt

# Query and display all Windows Servers; List by Name, IPv4Address, OperatingSystem
Get-ADComputer -Filter { (OperatingSystem -Like "Windows Server*") } -Property * | Format-List Name,ipv4*,OperatingSystem | Out-File C:\Results\All-Windows-Servers.txt

# Snippit to query and return IPv4Addres and associated MAC address
Get-NetIPConfiguration | 
  Select-Object @{n='IPv4Address';e={$_.IPv4Address[0]}}, 
         @{n='MacAddress'; e={$_.NetAdapter.MacAddress}}
#Out to file
Clear-Host
Get-NetAdapter | 
ForEach-Object {
        $PSitem | 
            Select-Object -Property Name, InterfaceDescription, ifIndex, Status, 
            MacAddress,  LinkSpeed,
            @{
                Name       = 'IPAddress'
                Expression = {(Get-NetIPAddress -InterfaceIndex ($PSItem).ifindex).IPv4Address}
            }
} | 
Export-Csv -Path 'C:\Results\NicDetails.csv'

## Not properties of Get-ADComputer
# MACAddress, IPSubnet, DefaultIPGateway, DNSServerSearchOrder,