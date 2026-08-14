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
    Get_SystemUptime_of_MultipleRemoteSystems_in_DifferentTimeZones.ps1

.DESCRIPTION
    		- Get system up time of multiple remote system in different time zones

.FUNCTIONALITY
    		- Get system up time of multiple remote system in different time zones

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Function - Logging file
function Logging($pingerror, $Computer, $UpTime)
{
	$outputfile = "\\SERVER\SHARE\...\log_GetSystemUptime.txt";
	
	$timestamp = (Get-Date).ToString();
	
	#$logstring = "Computer / Uptime: {0}, {1}" -f $Computer, $UpTime;
	$logstring = ($Server + "		" + $UpTime);
	#$logstring = ($UpTime);
	
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

function Get-UpTime
{
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
		[Alias("CN")]
		[String]$ComputerName = $Env:ComputerName,
		[Parameter(Position = 1, Mandatory = $false)]
		[Alias("RunAs")]
		[System.Management.Automation.Credential()]
		$Credential = [System.Management.Automation.PSCredential]::Empty
	)
	process
	{
		"{0} 	Uptime: {1:%d} Days {1:%h} Hours {1:%m} Minutes {1:%s} Seconds" -f $ComputerName,
		(New-TimeSpan -Seconds (Get-WmiObject Win32_PerfFormattedData_PerfOS_System -ComputerName $ComputerName -Credential $Credential).SystemUpTime)
	}
}

# Sets the Server Inclusion List from a Text File
$ServerList = Get-Content "\\SERVER\SHARE\...\targets_Uptime.txt"

ForEach ($Server in $ServerList)
{
# This function can be used in a pipeline
	$Uptime = $Server | Get-UpTime
	
# Dump results to logging function 
	Logging $False $Server $UpTime;
}