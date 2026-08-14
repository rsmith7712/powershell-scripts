<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 06/27/2017
    Organization: Domain, Inc.
    Filename: ContentReplication_Folder_Clear.ps1
    =========================================================
    .DESCRIPTION
        [ENTER A BRIEF DESCRIPTION OF SCRIPT AND ITS PURPOSE]

    .VERSION INFO
        [ENTER ANY CHANGES MADE HERE]
#>

# ----------------------------------------------------------------------------------------------
# Parameters

param (
    [Parameter(Mandatory=$true)][string]$computer = ""
)

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

function Clear-Patch ($path)
{
    Get-ChildItem -Path $path -Filter LD2016* | Remove-Item -Recurse -Force
}

function Clear-Others ($path)
{
    Get-ChildItem -Path $path -Recurse -Force | Remove-Item -Recurse -Force
}

# ----------------------------------------------------------------------------------------------
# Variables

$domainuser = "domain\orgsvc"
$domainpass = ConvertTo-SecureString "<password>" -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential $domainuser, $domainpass

# ----------------------------------------------------------------------------------------------
# Script


Write-Host "Select Option"
Write-Host "1. Clear C:\Patch"
Write-Host "2. Clear C:\Packages"
Write-Host "3. Clear C:\CORNERSTONE"
Write-Host "4. Clear C:\Program Files (x86)\LANDesk\LDClient\sdmcache\Patch"
Write-Host "5. Clear C:\Program Files (x86)\LANDesk\LDClient\sdmcache\Packages"
Write-Host "6. Clear C:\Program Files (x86)\LANDesk\LDClient\sdmcache\CORNERSTONE"
Write-Host "q - quit"

do
{
    $switch = Read-Host "Enter Selection"
    switch ($switch)
    {
        '1'
        {
            $path = "C:\Patch"
            Invoke-Command -Credential $creds -ComputerName $computer -ScriptBlock ${function:clear-patch} -ArgumentList $path
        }
        '2'
        {
            $path = "C:\Packages"
            Invoke-Command -Credential $creds -ComputerName $computer -ScriptBlock ${function:Clear-Others} -ArgumentList $path
        }
        '3'
        {
            $path = "C:\CORNERSTONE"
            Invoke-Command -Credential $creds -ComputerName $computer -ScriptBlock ${function:Clear-Others} -ArgumentList $path
        }
        '4'
        {
            $path = "C:\Program Files (x86)\LANDesk\LDClient\sdmcache\Patch"
            Invoke-Command -Credential $creds -ComputerName $computer -ScriptBlock ${function:clear-patch} -ArgumentList $path
        }
        '5'
        {
            $path = "C:\Program Files (x86)\LANDesk\LDClient\sdmcache\Packages"
            Invoke-Command -Credential $creds -ComputerName $computer -ScriptBlock ${function:Clear-Others} -ArgumentList $path
        }
        '6'
        {
            $path = "C:\Program Files (x86)\LANDesk\LDClient\sdmcache\CORNERSTONE"
            Invoke-Command -Credential $creds -ComputerName $computer -ScriptBlock ${function:Clear-Others} -ArgumentList $path
        }
        "q"
        {
            break
        }
    }
}
until ($switch -eq "q")