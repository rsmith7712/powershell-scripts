<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 3/30/2017
    Organization: Domain, Inc.
    Filename: Udrive_Sync_v.2.ps1
    Description: Syncs the content delivery folder of a remote machine.
    =========================================================
    .VERSION
        v.2 - initial script buildout

    .VERSION INFO
        [ENTER PREVIOUS VERSION INFO]
#>

# ----------------------------------------------------------------------------------------------
<# Logging
$stamp = Get-Date -Format "HHmmss"
$Script:Logfile = "C:\temp\#filename_$stamp.txt"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "VALUE, VALUE"
function Append-Log($message)
{
	Add-Content $Script:LogFile "$message"
}
#>
# ----------------------------------------------------------------------------------------------
#Variables

$computer = Read-Host "Enter Computer Name"

# ----------------------------------------------------------------------------------------------
#Functions

# ----------------------------------------------------------------------------------------------
#Script

psexec -u domain\helpdsk -p "<password>" \\$computer robocopy \\SERVER\SHARE\ContentDelivery C:\CONTENTDELIVERY /e