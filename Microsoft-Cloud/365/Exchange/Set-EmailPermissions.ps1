<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 02/02/2018
    Organization: Domain, Inc.
    Filename: Set-EmailPermissions.ps1
    =========================================================
    .DESCRIPTION
        Sets email full access permissions on a users email box.

    .VERSION INFO
        v1.0 - Initial script build.
#>

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = get-date -Format s | foreach {$_ -replace ":", "."}
$Script:Logfile = "C:\temp\FILENAME_$stamp.txt"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "User, OU, License Status"
function Append-Log($message)
{
    $thetime = Get-Date -Format t
	Add-Content $Script:LogFile "$message"
}

# ----------------------------------------------------------------------------------------------
# Functions

# ----------------------------------------------------------------------------------------------
# Variables

# ----------------------------------------------------------------------------------------------
# Script
