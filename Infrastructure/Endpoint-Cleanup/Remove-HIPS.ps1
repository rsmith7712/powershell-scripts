<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 08/29/2017
    Organization: Domain, Inc.
    Filename: remove-hips.ps1
    =========================================================
    .DESCRIPTION
        [ENTER A BRIEF DESCRIPTION OF SCRIPT AND ITS PURPOSE]

    .VERSION INFO
        [ENTER ANY CHANGES MADE HERE]
#>

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = get-date -Format s | foreach {$_ -replace ":", "."}
$Script:Logfile = "C:\temp\remove-hips_$stamp.txt"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "Starting removal of HIPs"
function Append-Log($message)
{
    $thetime = Get-Date -Format t
	Add-Content $Script:LogFile "$thetime - $message"
}

# ----------------------------------------------------------------------------------------------
# Variables

$guid = (Get-WmiObject -Class win32_product | where {$_.name -eq "mcafee host intrusion prevention"}).identifyingnumber

# ----------------------------------------------------------------------------------------------
# Script

#disables HIPs so it can be uninstalled.
$check = Get-WmiObject -Class win32_product | where {$_.name -eq "mcafee host intrusion prevention"}
if($check.name -eq "mcafee host intrusion prevention")
{
    Append-Log "Disabling HIPs"
    Start-Process -FilePath "C:\program files\mcafee\host intrusion prevention\clientcontrol.exe" -ArgumentList "/stop domaincorphelp" -Wait
    Append-Log "HIPs disabled succesfully"
    Append-Log "Starting uninstall process"
    Start-Process msiexec.exe -ArgumentList "/x $guid /quiet" -Wait
    $recheck = Get-WmiObject -Class win32_product | where {$_.name -eq "mcafee host intrusion prevention"}
    if($recheck -eq $true)
    {
        Append-Log "UNINSTALL FAILED, YOU FAILED, TRY AGAIN"
    }
    else 
    {
        Append-Log "Uninstall succesful.  You win one good boy point."
    }
}
else 
{
    Append-Log "HIPs not found."
}