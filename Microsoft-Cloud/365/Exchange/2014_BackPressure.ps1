# LEGAL
<# LICENSE
    MIT License, Copyright 2012 Richard Smith

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
    2014_BackPressure.ps1

.SYNOPSIS
Test-TransportServerBP.ps1 - Script to check Transport Servers for Back Pressure.

.DESCRIPTION 
Checks the event logs of Hub Transport servers for "back pressure" events.

.OUTPUTS
Results are output to the PowerShell window.

.PARAMETER server
Perform a check of a single server

.EXAMPLE
.\Test-TransportServerBP.ps1
Checks all Hub Transport servers in the organization and outputs the results to the shell window.

.EXAMPLE
.\Test-TransportServerBP.ps1 -server HO-EX2010-MB1
Checks the server HO-EX2010-MB1 and outputs the results to the shell window.

.LINK
http://exchangeserverpro.com/powershell-script-check-hub-transport-servers-for-back-pressure-events

.NOTES
Written By: Paul Cunningham
Website:	http://exchangeserverpro.com
Twitter:	http://twitter.com/exchservpro

Change Log
V1.0, 27/08/2012 - Initial version

.FUNCTIONALITY
    Checks the event logs of Hub Transport servers for "back pressure" events.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

param (
	[Parameter( Mandatory=$false)]
	[string]$server
)

#Add Exchange 2010 snapin if not already loaded
if (!(Get-PSSnapin | where {$_.Name -eq "Microsoft.Exchange.Management.PowerShell.E2010"}))
{
	Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction SilentlyContinue
}

#...................................
# Script
#...................................


#Check if a single server was specified
if ($server)
{
	#Run for single specified server
	try
	{
		[array]$servers = @(Get-ExchangeServer $server -ErrorAction Stop)
	}
	catch
	{
		#Couldn't find Exchange server of that name
		Write-Warning $_.Exception.Message
		
		#Exit because single server was specified and couldn't be found in the organization
		EXIT
	}
}
else
{
	#Get list of Hub Transport servers in the organization
	[array]$servers = @(Get-ExchangeServer | Where-Object {$_.IsHubTransportServer})
}

#Check each server
foreach($server in $servers)
{
	$events = @(Invoke-Command –Computername $server –ScriptBlock { Get-EventLog -LogName Application | Where-Object {$_.Source -eq "MSExchangeTransport" -and $_.Category -eq "ResourceManager"} })
	$count = $events.count

	if ($count -lt 1)
	{
		Write-Host "$server has no back pressure events found."
	}
	else
	{
		$lastevent = $events | Select-Object -First 1

		$now = Get-Date
		$timewritten = $lastevent.TimeWritten
		$ago = "{0:N0}" -f ($now - $timewritten).TotalHours 
		
		switch ($lastevent.EventID)
		{
			"15006" { $BPstate = "Critical (Diskspace)" }
			"15007" { $BPstate = "Critical (Memory)" }
			default { $BPstate = $lastevent.ReplacementStrings[1] }
		}

		Write-Host "$server is $BPstate as of $ago hours ago"

	}
}

