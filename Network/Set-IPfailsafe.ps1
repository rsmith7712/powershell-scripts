# LEGAL
<# LICENSE
    MIT License, Copyright 2016 Richard Smith

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
    Set-IPfailsafe_2_2.ps1

.SYNOPSIS
  Failback for IP Change
 
.DESCRIPTION
  Sets machine back to DHCP if it can't find it's Gateway. Tests for Gateway twice in 10 minutes before
	setting DHCP.
 
.NOTES
  Version:        1.0
  Author:         user26
  Creation Date:  11/23/2016
  Purpose/Change: Initial Version

.HISTORY

.FUNCTIONALITY
    Sets machine back to DHCP if it can't find it's Gateway. Tests for Gateway twice in 10 minutes before
    	setting DHCP.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Function Set-Hosts()
{
	#Wipes out the hosts file and resets it to the default
	$op = get-content C:\Windows\system32\drivers\etc\hosts | Select-Object -first 21
	#specifying the encoding is necessary, or the whole hosts file turns to gibberish.
	write-output $op | out-file -Encoding UTF8 C:\Windows\system32\drivers\etc\hosts
}

$adapter = Get-WmiObject -class win32_NetworkAdapterConfiguration -Filter 'ipenabled = "true"'
$script:ip_address = $adapter.ipaddress[0]
# parse ip address into octets
$script:ip_parsed = $script:ip_address.split(".")
# derive 1st 3 octets of ip address							
$script:ip_3_octets = $script:ip_parsed[0] + '.' + $script:ip_parsed[1] + '.' + $script:ip_parsed[2]
# derive gateway  ----- in stores, gateway is 1st three octets of the ip, with 1 as 4th octet
$script:gateway = $script:ip_3_octets + '.' + '1'

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