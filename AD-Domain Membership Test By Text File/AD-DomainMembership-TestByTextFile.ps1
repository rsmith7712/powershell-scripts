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
    AD-DomainMembership-TestByTextFile.ps1

.SYNOPSIS
    Test for system's domain membership status -- Pulling system names from a text file
    - Test for system's domain membership status; 
	- Pulling system names from a text file; 
	- Logging results in a text file

.FUNCTIONALITY
    Prompts for Input

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712 
        PowerShell Scripts - AD-DomainMembership-TestByTextFile
#>

# Import AD Module
Import-Module ActiveDirectory;
Write-Host "AD Module Imported";

# Function - Logging file
function Logging($pingerror, $Computer, $Membership)
{
	$outputfile = "\\DOMAIN.com\Shares\UTILITY\log_TestForDomainMembership.txt";
	
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

# Sets the Server Inclusion List from a Text File
$ServerList = Get-Content "\\FILE_SERVER\Shares\UTILITY\list_TestForDomainMembership.txt"

# ForEach Loop - Test each system listed in text file for domain membership status
ForEach ($Server in $ServerList)
{
	# Set timeout value so script doesn't keep hitting an unresponsive system
	$timeoutSeconds = 15
	
	# Test connection to target server
	Write-Host "Testing connection to target system";
	If (Test-Connection -CN $Server -Quiet)
	{
		Write-Host "Connection to target system successful";
		
		# Switch statement - Create variable and test system's domain membership
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
		}
		
		# Export results to logging function
		Logging $False $Server $Membership;
	}
}