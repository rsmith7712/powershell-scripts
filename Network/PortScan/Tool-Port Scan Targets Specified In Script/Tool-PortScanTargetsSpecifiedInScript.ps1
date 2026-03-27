# LEGAL
<# LICENSE
    MIT License, Copyright 2016 Richard Smith, Geoff Sweet

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
   Tool-PortScanTargetsSpecifiedInScript.ps1

.DESCRIPTION
	This script is designed to scan specific ports on a list of targets pulled
	from a text file. The script will generate a report of the results and export
	the report to a csv file.

.FUNCTIONALITY
	- Pulls list of targets from text file
	- Scans specified ports on each target
	- Generates report and exports to csv file

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

#>

# Import AD Module
Import-Module ActiveDirectory;
Write-Host "AD Module Imported";

# Enable PowerShell Remote Sessions
Enable-PSRemoting -Force;
Write-Host "PSRemoting Enabled";

# Set Execution Policy to Unrestricted
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
Write-Host "Execution Policy Set";

Function DetectTCPPorts{
	[cmdletbinding()]
	param ()
	
	$outputfile = "\\FILE_SERVER\Shares\UTILITY\log_rich-tcpPort.csv";
#	$outputfile = "\\FILE_SERVER\Shares\UTILITY\log_rich-tcpPort.txt";
	$timestamp = (Get-Date).ToString();
	$tcpConnStatus = ($Server+ "	-- Port in use: " + $TCPConn.Port);
	"$timestamp - $tcpConnStatus" | out-file $outputfile -Append;
	
	try{
		$TCPProperties = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()
		$TCPConns = $TCPProperties.GetActiveTcpListeners()
		foreach ($TCPConn in $TCPConns){
			if ($global:matchPorts -contains $TCPConn.Port){
				throw "$timestamp - $tcpConnStatus";
			}
		}
	}
	catch{
		$ErrorMessage = $_.Exception.InnerException.Message;
		Write-Error $_.Exception.Message;
	}
}

# Global array of ports to match on.
$global:matchPorts = "514", "8000", "8080", "8089", "9997";

# Sets the Server Inclusion List from a Text File
$ServerList = Get-Content "\\FILE_SERVER\Shares\UTILITY\list_TestPortHostTargets.txt"

ForEach ($Server in $ServerList){
	Write-Host "Starting";
	DetectTCPPorts
}