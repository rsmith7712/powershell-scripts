<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.127
	 Created on:   	8/22/2016 9:00 AM
	 Created by:   	@rsmith, @gsweet, @erocconi
	 Organization: 	
	 Filename:     	enable_PSRemoting.ps1
	===========================================================================
	.DESCRIPTION
		Enable PSRemoting on targeted OU
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
	$outputfile = "C:\log_EnablePSRemoting.txt";
	
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
$OUs = @("OU=Domain Controllers")
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
		
		Logging $False $Server;
	}
}