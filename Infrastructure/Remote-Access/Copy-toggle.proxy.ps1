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
# Variables

$computer = Read-Host "Enter Computer Name"
$shortcut = "\\SERVER\SHARE\...\Toggle Proxy Settings.lnk"
$vbs = "\\SERVER\SHARE\...\toggle.proxy.vbs"

# ----------------------------------------------------------------------------------------------
# Script

Copy-Item -Path $shortcut -Destination "\\$computer\C$\...\Toggle Proxy Settings.lnk" -Force
Copy-Item -Path $vbs -Destination "\\$computer\C$\...\toggle.proxy.vbs" -Force

$shortcutcheck = Test-Path -Path "\\$computer\C$\...\Toggle Proxy Settings.lnk"
$vbscheck = Test-Path -Path "\\$computer\C$\...\toggle.proxy.vbs"

if($shortcutcheck -eq $true)
{
    Write-Host "Shortcut Copied Succesfully"
}
else 
{
    Write-Host "Shortcut was not copied" -ForegroundColor Red
}

if($vbscheck -eq $true)
{
    Write-Host "Script Copied Succesfully"
}
else 
{
    Write-Host "Script was not copied" -ForegroundColor Red
}