

# This gets all the information I needed at the time..
# Need to add how to get it from all computers / devices on the network
# Export to a Csv



$nic_config = Get-WmiObject -computer . -class "win32_networkadapterconfiguration" | Where-Object {$_.defaultIPGateway -ne $null}

#$nic_config | fl
#$nic_config | select-object *

Write-Host "PSComputerName: " $nic_config.PSComputerName
Write-Host "DHCPEnabled: " $nic_config.DHCPEnabled
Write-Host "DHCPServer: " $nic_config.DHCPServer
Write-Host "IPAddress: " $nic_config.IPAddress
Write-Host "IPSubnet: " $nic_config.IPSubnet
Write-Host "DefaultIPGateway: " $nic_config.DefaultIPGateway
Write-Host "MACAddress: " $nic_config.MACAddress
Write-Host "DNSServerSearchOrder: " $nic_config.DNSServerSearchOrder
Write-Host "DNSDomainSuffixSearchOrder: " $nic_config.DNSDomainSuffixSearchOrder
