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
    Get_SystemUptime.ps1

.DESCRIPTION
    		- Get system up time of multiple remote system in different time zones
    		- Store results to be used later

.FUNCTIONALITY
    		- Get system up time of multiple remote system in different time zones
    		- Store results to be used later

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Import AD Module
Import-Module ActiveDirectory;
Write-Host "AD Module Imported";

# Function - Logging file
function Logging($pingerror, $Computer, $UpTime)
{
	$outputfile = "\\SERVER\SHARE\...\log_Uptime.txt";
	
	$timestamp = (Get-Date).ToString();
	
	#$logstring = "Computer / Uptime: {0}, {1}" -f $Computer, $UpTime;
	$logstring = ($Server+ "		" +$UpTime);
	
	"$timestamp - $logstring" | out-file $outputfile -Append;
	
	if ($pingerror -eq $false)
	{
		Write-Host "$timestamp - $logstring";
	}
	else
	{
		Write-Host "$timestamp - $logstring" -foregroundcolor red;
	}
	return $null;
}

function Get-SystemUpTime
{
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
		[Alias("CN")]
		[String[]]$ComputerName = $Env:ComputerName,
		[Parameter(Position = 1, Mandatory = $false)]
		[Alias("RunAs")]
		[System.Management.Automation.Credential()]
		$Credential = [System.Management.Automation.PSCredential]::Empty
	)
	process
	{
		foreach ($Name in $ComputerName)
		{
			Get-WmiObject -Class Win32_PerfFormattedData_PerfOS_System -ComputerName $Name -Credential $Credential |
			Select-Object { New-TimeSpan -Seconds $_.SystemUpTime } 
			
			#Select-Object @{ Name = "ComputerName"; Expression = { $_.__SERVER } },
			#			  @{ Name = "SystemUpTime"; Expression = { New-TimeSpan -Seconds $_.SystemUpTime } }
		}
	}
}

# Sets the Server Inclusion List from a Text File
$ServerList = Get-Content "\\SERVER\SHARE\...\targets_Uptime.txt"

ForEach ($Server in $ServerList)
{
	$UpTime = Get-SystemUpTime $Server | Sort-Object SystemUpTime
	
	#$Server | Get-SystemUpTime | Sort-Object SystemUpTime
	
	# Dump results to logging function 
	Logging $False $Server $UpTime;
}