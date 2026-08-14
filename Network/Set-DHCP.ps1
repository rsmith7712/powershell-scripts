<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: XX/XX/XXXX
    Organization: Domain, Inc.
    Filename: Set-DHCP.ps1
    =========================================================
    .DESCRIPTION
        [ENTER A BRIEF DESCRIPTION OF SCRIPT AND ITS PURPOSE]

    .VERSION INFO
        [ENTER ANY CHANGES MADE HERE]
#>

# ----------------------------------------------------------------------------------------------
# Functions

Function Set-Hosts()
{
	#Wipes out the hosts file and resets it to the default
	$op = get-content C:\Windows\system32\drivers\etc\hosts | Select-Object -first 21
	#specifying the encoding is necessary, or the whole hosts file turns to gibberish.
	write-output $op | out-file -Encoding UTF8 C:\Windows\system32\drivers\etc\hosts
}

# ----------------------------------------------------------------------------------------------
# Variables

$adapter = Get-WmiObject -class win32_NetworkAdapterConfiguration -Filter 'ipenabled = "true"'
$script:ip_address = $adapter.ipaddress[0]
# parse ip address into octets
$script:ip_parsed = $script:ip_address.split(".")
# derive 1st 3 octets of ip address							
$script:ip_3_octets = $script:ip_parsed[0] + '.' + $script:ip_parsed[1] + '.' + $script:ip_parsed[2]
# derive gateway  ----- in stores, gateway is 1st three octets of the ip, with 1 as 4th octet
$script:gateway = $script:ip_3_octets + '.' + '1'

# ----------------------------------------------------------------------------------------------
# Script

If (Test-Connection $script:gateway)
{
	Write-Host "New Gateway Found, No FailBack Required."
	Exit 0
}
Else
{
	Start-Sleep 600 # Waits 10 minutes to try again before setting back to DHCP
	If (Test-Connection $script:gateway)
	{
		Write-Host "New Gateway Found, No FailBack Required."
		Exit 0
	}
	Else
	{
		Write-Host "New Gateway Not Found, Failing Back to DHCP."
		Set-Hosts
		$adapter.EnableDHCP()
		Exit 0
	}
}
Exit 1
