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
    refsplunkRemoteAgentInstall.v3.ps1

.DESCRIPTION
    		Script copies 3 files to specified remote servers and installs Splunk Remote Agent

.FUNCTIONALITY
    		Script copies 3 files to specified remote servers and installs Splunk Remote Agent

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
Set-ExecutionPolicy Unrestricted
Write-Host "Execution Policy Set";

#Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force 

# Function - Logging file
function Logging($pingerror, $Computer)
{
	$outputfile = "\\SERVER\SHARE\...\splunk_RemoteAgentInstallLog.txt";
	
	$timestamp = (Get-Date).ToString();
	
	#$logstring = $logstring.Trim();
	$logstring = "Processed Computer: {0}" -f $Computer
	
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

# Sets the Inclusion OU
$OUs = @("OU=SplunkRemoteAgentInstall,OU=Domain Servers")
$SearchBase = "$OUs, DC=Domain, DC=com"

$GetServer = Get-ADComputer -LDAPFilter "(name=*)" -SearchBase $SearchBase 
$Servers = $GetServer.name

ForEach ($Server in $Servers){
	# Test connection to target server
	Write-Host "Before test connection to target server";
	If(Test-Connection -CN $Server -Quiet){
		Write-Host "After test connection to target server";
		Write-Host;

        # Create install folder - C:\Software\SplunkInstaller
        Invoke-Command â€“ComputerName $Server â€“scriptblock { New-Item -Path "C:\Software\SplunkInstaller" -ItemType directory â€“Force }
            
		# Copy Application MSI, Configuration File, and Batch File With Custom Launch Options
		Write-Host "Before Copy-Item section";
		Copy-Item -Path \\SERVER\SHARE\...\splunkforwarder-6.4.2-00f5bb3fa822-x64-release.msi -Destination \\$Server\c$\...\splunk_forwarder-6.4.2-00f5bb3fa822-x64-release.msi -Force
		Copy-Item -Path \\SERVER\SHARE\...\splunk_deploymentclient.conf -Destination \\$Server\c$\...\splunk_deploymentclient.conf -Force
		Copy-Item -Path \\SERVER\SHARE\...\splunk_PsExecInstallScript.bat -Destination \\$Server\c$\...\splunk_PsExecInstallScript.bat -Force
		Write-Host "After Copy-Item section";
		Write-Host;

		# Run Batch File Locally On Server 
		Write-Host "Before Splunk Install Batch File Execution";
		Invoke-Command -ComputerName $Server -ScriptBlock { c:\Software\SplunkInstaller\splunk_PsExecInstallScript.bat }
		Write-Host "After Splunk Install Batch File Execution section";
		
		Logging $False $Server;
		}
    }