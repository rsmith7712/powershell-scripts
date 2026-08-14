<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 4/12/2017
    Organization: Domain, Inc.
    Filename: disk_query.ps1
    =========================================================
    .DESCRIPTION
        [ENTER A BRIEF DESCRIPTION OF SCRIPT AND ITS PURPOSE]

    .VERSION INFO
        [ENTER ANY CHANGES MADE HERE]
#>

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = Get-Date -Format "HHmmss"
$Script:Logfile = "C:\temp\disk_query.txt"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "Computer, Free Space"
function Append-Log($message)
{
	Add-Content $Script:LogFile "$message"
}
# ----------------------------------------------------------------------------------------------
# Variables

$computers = @()
$computers += (Get-ADComputer -SearchBase "ou=store computers,ou=store computers,dc=domain,dc=com" -Filter *).name
$computers += (Get-ADComputer -SearchBase "ou=store jumpstart computers,ou=store computers,dc=domain,dc=com" -Filter *).name
$computers += (Get-ADComputer -SearchBase "ou=store additional computers,ou=store computers,dc=domain,dc=com" -Filter *).name

# ----------------------------------------------------------------------------------------------
# Functions

# ----------------------------------------------------------------------------------------------
# Script

foreach($computer in $computers)
{
    $freespace = ((Get-WmiObject Win32_LogicalDisk -ComputerName $computer -Filter "DeviceID='C:'").FreeSpace / 1GB)
    if($freespace -lt "50")
    {
        Append-Log "$computer, $freespace"
    }
}