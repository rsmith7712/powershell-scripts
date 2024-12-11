
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