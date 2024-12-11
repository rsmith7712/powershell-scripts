Get-NetAdapter | 
ForEach-Object {
        $PSitem | 
            Select-Object -Property Name, InterfaceDescription, ifIndex, Status, 
            MacAddress,  LinkSpeed,
            @{
                Name       = 'IPAddress'
                Expression = {(Get-NetIPAddress -InterfaceIndex ($PSItem).ifindex).IPv4Address}
            }
} | Export-Csv -Path 'C:\Results\NicDetails.csv'

$nic_config = Get-WmiObject -computer . -class "win32_networkadapterconfiguration" | Where-Object {$_.defaultIPGateway -ne $null}

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

#$ArrComputers =  ".", "PC152", "PC747"
#Specify the list of PC names in the line above. "." means local system

Clear-Host
foreach ($Computer in $ArrComputers) 
{
    $computerSystem = get-wmiobject Win32_ComputerSystem -Computer $Computer
    $computerBIOS = get-wmiobject Win32_BIOS -Computer $Computer
    $computerOS = get-wmiobject Win32_OperatingSystem -Computer $Computer
    $computerCPU = get-wmiobject Win32_Processor -Computer $Computer
    $computerHDD = Get-WmiObject Win32_LogicalDisk -ComputerName $Computer -Filter drivetype=3
        write-host "System Information for: " $computerSystem.Name -BackgroundColor DarkCyan
        "-------------------------------------------------------"
        "Manufacturer: " + $computerSystem.Manufacturer
        "Model: " + $computerSystem.Model
        "Serial Number: " + $computerBIOS.SerialNumber
        "CPU: " + $computerCPU.Name
        "HDD Capacity: "  + "{0:N2}" -f ($computerHDD.Size/1GB) + "GB"
        "HDD Space: " + "{0:P2}" -f ($computerHDD.FreeSpace/$computerHDD.Size) + " Free (" + "{0:N2}" -f ($computerHDD.FreeSpace/1GB) + "GB)"
        "RAM: " + "{0:N2}" -f ($computerSystem.TotalPhysicalMemory/1GB) + "GB"
        "Operating System: " + $computerOS.caption + ", Service Pack: " + $computerOS.ServicePackMajorVersion
        "User logged In: " + $computerSystem.UserName
        "Last Reboot: " + $computerOS.ConvertToDateTime($computerOS.LastBootUpTime)
        ""
        "-------------------------------------------------------"
}