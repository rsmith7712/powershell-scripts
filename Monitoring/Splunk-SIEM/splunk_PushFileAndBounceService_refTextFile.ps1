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
    splunk_PushFileAndBounceService_refTextFile.ps1

.DESCRIPTION
    		Script copies files to specified remote servers and bounces specified service

.FUNCTIONALITY
    		Script copies files to specified remote servers and bounces specified service

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Import AD Module
Import-Module ActiveDirectory;
Write-Host "AD Module Imported";

# Function - Logging file
function Logging($pingerror, $Computer, $Service)
{
	$outputfile = "\\SERVER\SHARE\...\log_PushFileAndBounceService.txt";
	
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
$ServerList = Get-Content "\\SERVER\SHARE\...\list_PushFileAndBounceService_refTextFile.txt"

ForEach ($Server in $ServerList)
{
	# Test connection to target server
	Write-Host "Test connection to target server";
	If (Test-Connection -CN $Server -Quiet)
	{
		
		Write-Host "Stopping Splunk Service";
		Stop-Service -InputObject $(Get-Service -Computer $Server -Name SplunkForwarder)
		Start-Sleep -Seconds 15
		
		# Copy file to remote system
		Write-Host "Copying files to remote system";
		Copy-Item -Path \\SERVER\SHARE\...\server.conf -Destination \\$Server\c$\"Program Files"\SplunkUniversalForwarder\etc\system\local\server.conf -Force
		Write-Host "File copy completed";
		Write-Host;
		
		# Change service status from whatever to Automatic
		Set-Service â€“Name SplunkForwarder â€“Computer $Server â€“StartupType "Automatic"
				
		# Remote Start the Splunk Forwarder Service
		Write-Host "Starting Splunk Service";
		Start-Service -InputObject $(Get-Service -Computer $Server -Name SplunkForwarder)
		
		# Check on service status and store in variable to be called by Logging Function
		Write-Host "Checking Service Status";
		$ServiceCheck = Get-Service -Name SplunkForwarder -ErrorAction silentlycontinue -ComputerName $Server;
		
		Logging $False $Server $ServiceCheck;
	}
}