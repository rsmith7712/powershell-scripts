# LEGAL
<# LICENSE
    MIT License, Copyright 2016 Geoff Sweet, Richard Smith

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
    AD-TestForDomainMembership_ByOU.ps1

.SYNOPSIS
    Powershell script that will get the stale records from the zone and match 
	them with the computer object in AD. Then use, the OperatingSystem field 
	value of that computer object to decide whether you would delete the A record 
	or not. In the end, you can have the script send you an email with the 
	report so you can have a Windows scheduled task do that for you every 
	Saturday or so!

.FUNCTIONALITY
    Prompts for Input

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712 
        PowerShell Scripts - AD-TestForDomainMembership_ByOU
#>

# Import AD Module
Import-Module ActiveDirectory;
Write-Host "AD Module Imported";

# Enable PowerShell Remote Sessions
Enable-PSRemoting -Force;
Write-Host "PSRemoting Enabled";

# Function - Logging file
function Logging($pingerror, $Computer, $Membership)
{
	$outputfile = "\\FILE_SERVER\Shares\UTILITY\log_TestForDomainMembership.txt";
	
	$timestamp = (Get-Date).ToString();
	
	$logstring = "Computer / Domain Status: {0}, {1}" -f $Computer, $Membership;
	
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

# Get details of this computer
$computer = Get-WmiObject -Class Win32_ComputerSystem

# Display details
"System Name: {0}" -f $computer.name
"Domain     : {0}" -f $computer.domain

# Sets the Inclusion OU
$OUs = @("OU=Domain Servers")
$SearchBase = "$OUs, DC=DOMAIN, DC=com"

$GetServer = Get-ADComputer -LDAPFilter "(name=*)" -SearchBase $SearchBase
$Servers = $GetServer.name

ForEach ($Server in $Servers)
{
	# Test connection to target server
	Write-Host "Before test connection to target server";
	If (Test-Connection -CN $Server -Quiet)
	{
		Write-Host "After test connection to target server";
		Write-Host;
		
		$Membership = gwmi -Class win32_computersystem | select -ExpandProperty domainrole
		switch ($Membership)
		{
			0 { "Standalone Workstation" }
			1 { "Member Workstation" }
			2 { "Standalone Server" }
			3 { "Member Server" }
			4 { "Backup Domain Controller" }
			5 { "Primary Domain Controller" }
			default { "Domain Membership Unknown" }
		} # end switch
		
		Logging $False $Server $Membership;
	}
}
