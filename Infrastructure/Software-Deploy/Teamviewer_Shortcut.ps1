<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 08/01/2017
    Organization: Domain, Inc.
    Filename: Teamviewer_Shortcut.ps1
    =========================================================
    .DESCRIPTION
        [ENTER A BRIEF DESCRIPTION OF SCRIPT AND ITS PURPOSE]

    .VERSION INFO
        [ENTER ANY CHANGES MADE HERE]
#>

# ----------------------------------------------------------------------------------------------
# Variables

$path = "Z:\software\teamviewer\TeamViewerQS.exe"
$dest = "C:\software\TeamViewer\TeamViewerQS.exe"

$shortcutpath = "C:\programdata\Microsoft\windows\Start Menu\TeamViewerQS.lnk"
$targetpath = "C:\Software\TeamViewer\teamviewerqs.exe"

# ----------------------------------------------------------------------------------------------
# Script

Copy-Item -Path $path -Destination $dest -Force

$wscriptshell = New-Object -ComObject wscript.shell
$shortcut = $wscriptshell.CreateShortcut($shortcutpath)
$shortcut.TargetPath = $targetpath
$shortcut.Save()