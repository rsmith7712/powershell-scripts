<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 05/05/2017
    Organization: Domain, Inc.
    Filename: fix_sql.ps1
    =========================================================
    .DESCRIPTION
        Checks to see if sql server service is running on a machine and starts it if the service is stopped.

    .VERSION INFO
        v1.0 - Intitial script buildout
#>

# ----------------------------------------------------------------------------------------------
# Variables

$computer = Read-Host "Enter Computer Name"
$services = Get-Service -ComputerName $computer -Name *SQL*

# ----------------------------------------------------------------------------------------------
# Script

foreach($service in $services)
{
    if($service.status -eq "Stopped")
    {
        Start-Service -Name [string]$service.name
        Write-Host $service.name "started"
        Set-Service -Name [string]$service.name -StartupType Automatic
        Write-Host $service.name "set to automatic startup behavior"
    }
    else 
    {
        Write-Host $service.name "already running"
    }
}