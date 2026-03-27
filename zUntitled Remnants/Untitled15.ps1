# LEGAL
<# LICENSE
    MIT License, Copyright 2025 Richard Smith

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the “Software”),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    IN THE SOFTWARE.
#>
# GENERAL SCRIPT INFORMATION
<#
.NAME
    Untitled15.ps1

.DESCRIPTION
    This script is designed to perform various tasks related to Active Directory
    and network configuration. The script includes functionality for importing the
    Active Directory module, enabling PowerShell remoting, setting execution
    policies, and defining variables for servers and services.

.FUNCTIONALITY
    The script is designed to perform various tasks related to Active Directory
    and network configuration. The script includes functionality for importing the
    Active Directory module, enabling PowerShell remoting, setting execution
    policies, and defining variables for servers and services. The script can be
    modified to include additional functionality as needed.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

#>

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