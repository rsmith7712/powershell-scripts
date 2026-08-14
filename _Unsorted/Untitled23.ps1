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
    Untitled23.ps1

.DESCRIPTION
    This script is designed to collect network adapter information from local and remote
    computers. The script includes functionality for retrieving MAC
    address, IP address, and other network adapter details, and exporting the
    information to a CSV file.

.FUNCTIONALITY
    This script is designed to collect network adapter information from local and
    remote computers. The script includes functionality for retrieving MAC
    address, IP address, and other network adapter details, and exporting the
    information to a CSV file. The script can be modified to include additional
    functionality as needed.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

#>

$nic_config = Get-WmiObject -computer . -class "win32_networkadapterconfiguration" | Where-Object {$_.DefaultIPGateway -ne $null}

Write-Host "PSComputerName: " $nic_config.PSComputerName
Write-Host "DHCPEnabled: " $nic_config.DHCPEnabled
Write-Host "DHCPServer: " $nic_config.DHCPServer
Write-Host "IPAddress: " $nic_config.IPAddress
Write-Host "IPSubnet: " $nic_config.IPSubnet
Write-Host "DefaultIPGateway: " $nic_config.DefaultIPGateway
Write-Host "MACAddress: " $nic_config.MACAddress
Write-Host "DNSServerSearchOrder: " $nic_config.DNSServerSearchOrder
Write-Host "DNSDomainSuffixSearchOrder: " $nic_config.DNSDomainSuffixSearchOrder

# Remote System Information
# Shows hardware and OS details from a list of PCs

# Load the Microsoft Active Directory Module
Import-Module ActiveDirectory

# Get a list of all computer names
$ArrComputers = Get-ADComputer -Filter *

Clear-Host
foreach ($Computer in $ArrComputers)
{
    #$computerSystem = get-wmiobject Win32_ComputerSystem -Computer $Computer
    $computerSystem = get-wmiobject win32_networkadapterconfiguration -Computer $Computer
    $dhcpE = get-wmiobject win32_networkadapterconfiguration -Computer $Computer
    $dhcpS = get-wmiobject win32_networkadapterconfiguration -Computer $Computer
    $ipaddy = get-wmiobject win32_networkadapterconfiguration -Computer $Computer
    $sub = get-wmiobject win32_networkadapterconfiguration -Computer $Computer
    $gtwy = get-wmiobject win32_networkadapterconfiguration -Computer $Computer
    $mac = get-wmiobject win32_networkadapterconfiguration -Computer $Computer
    $dnsS = get-wmiobject win32_networkadapterconfiguration -Computer $Computer
    $dnsD = get-wmiobject win32_networkadapterconfiguration -Computer $Computer

        write-host "System Information for: " $computerSystem.Name -BackgroundColor DarkCyan
        "-------------------------------------------------------"
        "PSComputerName: " + $computerSystem.PSComputerName
        "DHCPEnabled: " + $dhcpE.DHCPEnabled
        "DHCPServer: " + $dhcpS.DHCPServer
        "IPAddress: " + $ipaddy.IPAddress
        "IPSubnet: " + $sub.IPAddress
        "DefaultIPGateway: " + $gtwy.DefaultIPGateway
        "MACAddress: " + $mac.MACAddress
        "DNSServerSearchOrder: " + $dnsS.DNSServerSearchOrder
        "DNSDomainSuffixSearchOrder: " + $dnsD.DNSDomainSuffixSearchOrder
        ""
        "-------------------------------------------------------"
}
Get-WmiObject -computer . -class "win32_networkadapterconfiguration" | Where-Object {$_.PSComputerName -ne $null, $_.DHCPEnabled -ne $null, $_.DHCPServer -ne $null, $_.IPAddress -ne $null, $_.IPSubnet -ne $null, $_.DefaultIPGateway -ne $null, $_.MACAddress -ne $null, $_.DNSServerSearchOrder -ne $null, $_.DNSDomainSuffixSearchOrder -ne $null}
Get-WmiObject -computer . -class "win32_networkadapterconfiguration" | Where-Object {$_.PSComputerName -ne $null}