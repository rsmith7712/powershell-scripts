# LEGAL
<# LICENSE
    MIT License, Copyright 2016 Richard Smith, Eric Rocconi, Geoff Sweet,
                                Alex Paradis, Matt Miller, Damien Gibson

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
    AD-RemoteAgentInstallrefTextFile.ps1

.SYNOPSIS
    Script copies 3 files to specified remote servers and installs Remote Agent

.FUNCTIONALITY
    Prompts for Input

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts - AD-Remote Agent Install ref Text File
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
	$outputfile = "\\FILE_SERVER\Shares\UTILITY\log_RemoteAgentInstall.txt";
	
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
$ServerList = Get-Content "\\FILE_SERVER\Shares\UTILITY\list_ServerTargetList.txt"

ForEach ($Server in $ServerList)
{
	# Test connection to target server
	Write-Host "Testing connection to target server";
	If (Test-Connection -CN $Server -Quiet)
	{
		# Create install folder - C:\Software\xInstaller
		Invoke-Command –ComputerName $Server –scriptblock { New-Item -Path "C:\Software\xInstaller" -ItemType directory –Force }
		
		# Copy Application MSI, Configuration File, and Batch File With Custom Launch Options
		Write-Host "Before Copy-Item section";
		Copy-Item -Path \\FILE_SERVER\Shares\Install\UTILITY\<app name here with extension> -Destination \\$Server\c$\Software\xFolder\<app name here with extension> -Force
		Copy-Item -Path \\FILE_SERVER\Shares\Install\UTILITY\<app name here with extension> -Destination \\$Server\c$\Software\xFolder\<app name here with extension> -Force
		Copy-Item -Path \\FILE_SERVER\Shares\Install\UTILITY\<app name here with extension> -Destination \\$Server\c$\Software\xFolder\<app name here with extension> -Force
		Write-Host "After Copy-Item section";
		Write-Host;
		
		# Run Batch File Locally On Server 
		Write-Host "Before Install Batch File Execution";
		Invoke-Command -ComputerName $Server -ScriptBlock { c:\Software\xFolder\<app name here with extension> }
		Write-Host "After Install Batch File Execution section";
		
		# Stop Service
		Write-Host "Stopping Service";
		Stop-Service -InputObject $(Get-Service -Computer $Server -Name <service name>)
		Start-Sleep -Seconds 15
		
		# Copy *FIX* Server.Conf file to remote system
		Write-Host "Copying new Server.conf file to remote system";
		Copy-Item -Path \\FILE_SERVER\Shares\UTILITY\<app name here with extension> -Destination \\$Server\c$\"Program Files"\xFolder\<app name here with extension> -Force
		Write-Host "File copy completed";
		Write-Host;
		
		# Change service status from whatever to Automatic
		Set-Service –Name <service name> –Computer $Server –StartupType "Automatic"
		Write-Host "Setting service to Automatic start";
		
		# Remote Start the Service
		Write-Host "Starting Service";
		Start-Service -InputObject $(Get-Service -Computer $Server -Name <service name>)
		
		# Check on service status and store in variable to be called by Logging Function
		Write-Host "Checking Service Status";
		$ServiceCheck = Get-Service -Name <service name> -ErrorAction silentlycontinue -ComputerName $Server;
		
		# Dump results to logging function 
		Logging $False $Server $ServiceCheck;
	}
}