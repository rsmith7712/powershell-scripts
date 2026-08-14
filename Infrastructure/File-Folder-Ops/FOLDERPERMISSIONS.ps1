<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: XX/XX/XXXX
    Organization: Domain, Inc.
    Filename: __TEMPLATE__.ps1
    =========================================================
    .DESCRIPTION
        [ENTER A BRIEF DESCRIPTION OF SCRIPT AND ITS PURPOSE]

    .VERSION INFO
        [ENTER ANY CHANGES MADE HERE]
#>

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = get-date -Format s | foreach {$_ -replace ":", "."}
$Script:Logfile = "C:\temp\folders.csv"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile ""
function Append-Log($message)
{
    $thetime = Get-Date -Format t
	Add-Content $Script:LogFile "$message"
}

# ----------------------------------------------------------------------------------------------
# Functions

# ----------------------------------------------------------------------------------------------
# Variables

$folders = (get-childitem \\SERVER\SHARE\...\treasury -directory -recurse).fullname

# ----------------------------------------------------------------------------------------------
# Script

foreach($folder in $folders)
{
    $array = @()
    $array += (Get-Acl -Path $folder).access.identityreference
    Append-Log "$folder, $array"
}