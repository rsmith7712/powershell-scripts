<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 10/25/2017
    Organization: Domain, Inc.
    Filename: check-offlinefiles.ps1
    =========================================================
    .DESCRIPTION
        runs via a scheduled task to verify that offline files is disabled.

    .VERSION INFO
        v1 - Intitial script buildout
#>

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = get-date -Format s | foreach {$_ -replace ":", "."}
$Script:Logfile = "C:\temp\check-offlinefiles_$stamp.txt"
New-Item -Path $Script:Logfile -ItemType File -Force | Out-Null
Add-Content $Script:Logfile "Service Status, Action Taken"
function Append-Log($message)
{
    $thetime = Get-Date -Format t
	Add-Content $Script:LogFile "$message"
}

# ----------------------------------------------------------------------------------------------
# Script

$check = (get-service -Name CscService).Status

if($check -eq "running")
{
    Get-Service -Name CscService | Stop-Service | Set-Service -StartupType Disabled
    Append-Log "Running, Stopped and Disabled"
}
else 
{
    Append-Log "Stopped, no action"
}