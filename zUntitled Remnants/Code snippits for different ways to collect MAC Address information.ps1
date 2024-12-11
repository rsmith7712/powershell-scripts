### Code snippits for different ways to collect MAC Address information ###



#Solution 1
Get-CimInstance -Class "Win32_NetworkAdapterConfiguration" -Filter "IPEnabled='True'" -ComputerName . | 
Select-Object -Property MACAddress, Description

# Solution 2
Get-WmiObject -Class "Win32_NetworkAdapterConfiguration" -Filter "IPEnabled='True'" -ComputerName . | 
Select-Object -Property MACAddress, Description

# Solution 3
getmac.exe /s .

# Solution 4
# Network Adapter(s)
		"`t`t`t`tNetwork Adapter(s)"
		$props=@(
		    @{Label="Description"; Expression = {$_.Description}},
		    @{Label="IPAddress"; Expression = {$_.IPAddress}},
		    @{Label="IPSubnet"; Expression = {$_.IPSubnet}},
		    @{Label="DefaultIPGateway"; Expression = {$_.DefaultIPGateway}},
		    @{Label="MACAddress"; Expression = {$_.MACAddress}},
		    @{Label="DNSServerSearchOrder"; Expression = {$_.DNSServerSearchOrder}},
		    @{Label="DHCPEnabled"; Expression = {$_.DHCPEnabled}}
		)
Get-WmiObject "Win32_NetworkAdapterConfiguration" -ComputerName . -Filter "IPEnabled = 'True'" | Format-List $props


# Solution 5
# get list of all computers in AD
$remotecomputer = get-adcomputer -filter *

$Net = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $remotecomputer
$Net | Select-Object Description,IPAddress,MACAddress


# Solution 6
# get list of all computers in AD
$remotecomputer = get-adcomputer -filter *

invoke-command  -computername $remotecomputer -scriptblock {
    get-netadapter
}


# Solution 7
# get list of all computers in AD
$computers = get-adcomputer -filter *

# Grab the ComputerName and MACAddress
$result = Get-WmiObject -ComputerName $computers -Class "Win32_NetworkAdapterConfiguration" -Filter 'ipenabled = "true"' |
    Select-Object -Property PSComputerName, MacAddress

$result | Export-Csv C:\Results\Computers.csv -Delimiter ";" -NoTypeInformation


# Solution 8
$Computers = (Get-ADComputer -Filter {enabled -eq $true} -Property Name).Name
$result = ForEach ($Computer in $Computers){
    If (Test-Connection -Quiet -Count 1 -Computer $Computer){
        [PSCustomObject]@{
            ComputerName = $Computer
            MAC = (Invoke-Command {
                     (Get-WmiObject "Win32_NetworkAdapterConfiguration" -Filter 'ipenabled = "true"').MACAddress -Join ', '
                  } -ComputerName $Computer)
            Online = $True
            DateTime = [DateTime]::Now
        }
    } Else {
        [PSCustomObject]@{
            ComputerName = $Computer
            MAC = ''
            Online = $False
            DateTime = [DateTime]::Now
        }
    }
}
$result | Export-Csv C:\Results\Computers.csv -Delimiter ";" -NoTypeInformation