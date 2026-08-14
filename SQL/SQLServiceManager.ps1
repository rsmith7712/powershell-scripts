<#
    .INFORMATION
    =========================================================
    Created By:   user21
    Created On:   09/26/2017
    Organization: Domain, Inc.
    Filename:     SQLServiceManager.ps1
    =========================================================
    .DESCRIPTION
        Manages the SQL Express Service.  Manages Restarting / Starting of the service.

    .VERSION INFO
        v1 - Initial build.
#>

# Elevating script to bypass UAC roadblocks
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
	Echo "This script must be run As Admin"
	Break
}

# Function - Logging file
function Logging($pingerror, $Computer, $Service)
{
	$outputfile = "\\SERVER\SHARE\...\log_SQLServiceStatus.txt";
	
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
