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
		Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName . -Filter "IPEnabled = 'True'" |
		 Format-List $props