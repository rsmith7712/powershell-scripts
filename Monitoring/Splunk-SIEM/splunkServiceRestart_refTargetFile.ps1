# LEGAL
<# LICENSE
    MIT License, Copyright 2017 Richard Smith

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
    splunkServiceRestart_refTargetFile.ps1

.DESCRIPTION
    		A description of the file.

.FUNCTIONALITY
    		A description of the file.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Elevating script permissions to bypass UAC roadblocks
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
	Echo "This script needs to be run As Admin"
	Break
}

# Import AD Module
Import-Module ActiveDirectory;
Write-Host "AD Module Imported";

# Enable PowerShell Remote Sessions
Enable-PSRemoting -Force;
Write-Host "PSRemoting Enabled";

# Set Execution Policy to Unrestricted
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
Write-Host "Execution Policy Set";

# Function - Logging file
function Logging($pingerror, $Computer, $Service)
{
	$outputfile = "\\SERVER\SHARE\...\log_SplunkServiceStatus.txt";
	
	$timestamp = (Get-Date).ToString();
	
	$logstring = "Computer / Service Status: {0}, {1}, {2}" -f $Computer, $Service.Name, $Service.Status;
	
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

# Sets the Server Inclusion List from a Text File
$ServerList = Get-Content "\\SERVER\SHARE\...\list_SplunkServiceTargetList.txt"

ForEach ($Server in $ServerList)
{
	# Test connection to target server
	Write-Host "Testing connection to target server";
	If (Test-Connection -CN $Server -Quiet)
	{	
		# Stop Splunk Service
		Write-Host "Stopping Splunk Service";
		Stop-Service -InputObject $(Get-Service -Computer $Server -Name SplunkForwarder)
		Start-Sleep -Seconds 15
		
		# Change service status from whatever to Automatic
		Set-Service â€“Name SplunkForwarder â€“Computer $Server â€“StartupType "Automatic"
		Write-Host "Setting SplunkForwarder service to Automatic start";
		
		# Remote Start the Splunk Forwarder Service
		Write-Host "Starting SplunkForwarder Service";
		Start-Service -InputObject $(Get-Service -Computer $Server -Name SplunkForwarder)
		
		# Check on service status and store in variable to be called by Logging Function
		Write-Host "Checking Service Status";
		$ServiceCheck = Get-Service -Name SplunkForwarder -ErrorAction silentlycontinue -ComputerName $Server;
		
		# Dump results to logging function 
		Logging $False $Server $ServiceCheck;
	}
}
