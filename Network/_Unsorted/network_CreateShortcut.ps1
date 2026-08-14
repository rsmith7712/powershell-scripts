<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.127
	 Created on:   	7/22/2016 9:40 AM
	 Created by:   	Richard Smith
	 Organization: 	
	 Filename:     	network_CreateShortcut.ps1
	===========================================================================
	.DESCRIPTION
		Create desktop shortcut with PowerShell
#>

$Shell = New-Object -ComObject WScript.Shell
$Shortcut = $Shell.CreateShortcut("$Env:Public\Desktop\Google.com.lnk")
$Shortcut.TargetPath = "https://www.google.com"
$Shortcut.IconLocation = "shell32.dll,43"
$Shortcut.Save()