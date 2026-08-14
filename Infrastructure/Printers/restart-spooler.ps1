<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 12/14/2017
    Organization: Domain, Inc.
    Filename: Restart-Spooler.ps1
    =========================================================
    .DESCRIPTION
        Used to clear the print queue and restart the spooler service on a print server.

    .VERSION INFO
        v.1 - Initial script build. 
#>

# ----------------------------------------------------------------------------------------------
# Functions

function restart_spooler ($computer)
{
	$servicecheck = Get-Service -ComputerName $computer -Name Spooler
	if($servicecheck.status -eq "Running")
	{
		$servicecheck | Stop-Service -Force
	}
	Get-ChildItem -Path "\\$computer\C$\...\printers" -Recurse | ForEach-Object {Remove-Item -Recurse -Path $_.FullName}
	$servicecheck | Start-Service
}

function show-menu
{
	Write-Host "Please Select The Server
	1. domainps1
	2. st2-ps1
	3. Quit"
}


# ----------------------------------------------------------------------------------------------
# Script

do
{
	show-menu
	$server = Read-Host "Select Server"
	switch ($server)
	{
		'1' {restart_spooler "domainps1"} 
		'2' {restart_spooler "st2-ps1"} 
		'3' { break }
	}
}
until ($server -eq '3')
