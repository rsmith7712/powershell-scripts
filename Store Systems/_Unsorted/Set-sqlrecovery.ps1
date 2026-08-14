<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 09/21/2017
    Organization: Domain, Inc.
    Filename: Set-sqlrecovery.ps1
    =========================================================
    .DESCRIPTION
        [ENTER A BRIEF DESCRIPTION OF SCRIPT AND ITS PURPOSE]

    .VERSION INFO
        [ENTER ANY CHANGES MADE HERE]
#>

# ----------------------------------------------------------------------------------------------
# Logging
#$stamp = get-date -Format s | foreach {$_ -replace ":", "."}
$Script:Logfile = "C:\temp\set-sqlrecovery.txt"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "Computer, script"
function Append-Log($message)
{
    $thetime = Get-Date -Format t
	Add-Content $Script:LogFile "$message"
}

# ----------------------------------------------------------------------------------------------
# Functions

function Set_recovery ($computer) {

    sc.exe \\$computer failure "MSSQL$`SQLEXPRESS" command= 'powershell.exe -executionpolicy bypass -file C:\temp\send-mailalert.ps1' actions= restart/15000/restart/15000/run/15000 reset= 0
    
}

function Copy_script ($computer) {

    Copy-Item -Path C:\temp\send-mailalert.ps1 -Destination \\$computer\C$\...\send-mailalert.ps1 -Force
    
}

# ----------------------------------------------------------------------------------------------
# Variables

#$computers = Read-Host "Enter Computer Name"
$computers = (Get-ADComputer -SearchBase "ou=store computers,ou=store computers,dc=domain,dc=com" -Filter *).name

# ----------------------------------------------------------------------------------------------
# Script

foreach ($computer in $computers)
{
    $checkpath = "\\$computer\C$\...\send-mailalert.ps1"
    Copy_script $computer
    if(!(Test-Path $checkpath))
    {
        Append-Log "$computer, Not Copied"
    }
    else 
    {
        Append-Log "$computer, Script Copied"
    }
    Set_recovery $computer
}