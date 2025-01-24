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

.SYNOPSIS
    - Port scanning script targeted at specific ports
	- Pulling targets from text file 
	- Generate report and dump to csv file

.FUNCTIONALITY
    Prompts for Input

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts - Tool-Port Scan Targets Specified In Script
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