<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 7/20/2017
    Organization: Domain, Inc.
    Filename: Restart-CompleteviewServer.ps1
    =========================================================
    .DESCRIPTION
        A script used to restart completeview DVR server services on completeview servers.

    .VERSION INFO
        v1 - intial script buildout
#>

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = get-date -Format s | foreach {$_ -replace ":", "."}
$Script:Logfile = "C:\temp\Restart-CompleteviewServer_$stamp.csv"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "Hostname, DVR, AdminService Status, Action, ConfigService Status, Action, ServerService Status, Action"
function Append-Log($message)
{
    $thetime = Get-Date -Format t
	Add-Content $Script:LogFile "$message"
}

# ----------------------------------------------------------------------------------------------
# Functions

function Restart-Completeview($DVR)
{
    #used for logging
    $adminservice = $null
    $serverservice = $null
    $configservice = $null

    #gets the services that are running on the target computer.
    $services = Get-Service -ComputerName $DVR -Name completeview*
    foreach($service in $services)
    {
        if($service.Name -eq "completeview administrative service")
        {
            if($service.Status -eq "running")
            {
                $service | Stop-Service
                Start-Sleep -Seconds 10
                $service | Start-Service
                $admninservice = "Running, Restarted, "
            }
            else 
            {
                $service | start-service
                $adminservice = "Stopped, Started, "
            }
        }
        elseif($service.Name -eq "completeview config server")
        {
            if($service.Status -eq "running")
            {
                $service | Stop-Service
                Start-Sleep -Seconds 10
                $service | Start-Service
                $configservice = "Running, Restarted, "
            }
            else 
            {
                $service | start-service
                $configservice = "Stopped, Started, "
            }
        }
        elseif($service.Name -eq "completeview server")
        {
            if($service.Status -eq "running")
            {
                $service | Stop-Service
                Start-Sleep -Seconds 10
                $service | Start-Service
                $serverservice = "Running, Restarted"
            }
            else 
            {
                $service | start-service
                $serverservice = "Stopped, Started"
            }
        }
    }
    #returns logging values
    return $adminservice
    return $configservice
    return $serverservice
}

# ----------------------------------------------------------------------------------------------
# Variables

$store = Read-Host "Enter UFO_NUMBER"
[string]$DVR = $store + "DVR1"

#used for logging
$adminservice = $null
$configservice = $null
$serverservice = $null

# ----------------------------------------------------------------------------------------------
# Script

#Restart-Completeview $DVR

#gets the services that are running on the target computer.
$services = Get-Service -ComputerName $DVR -Name completeview*

foreach($service in $services)
{
    if($service.Name -eq "completeview administrative service")
    {
        if($service.Status -eq "running")
        {
            $service | Stop-Service
            Start-Sleep -Seconds 10
            $service | Start-Service
            $admninservice = "Running, Restarted, "
        }
        else 
        {
            $service | start-service
            $adminservice = "Stopped, Started, "
        }
    }
    elseif($service.Name -eq "completeview config server")
    {
        if($service.Status -eq "running")
        {
            $service | Stop-Service
            Start-Sleep -Seconds 10
            $service | Start-Service
            $configservice = "Running, Restarted, "
        }
        else 
        {
            $service | start-service
            $configservice = "Stopped, Started, "
        }
    }
    elseif($service.Name -eq "completeview server")
    {
        if($service.Status -eq "running")
        {
            $service | Stop-Service
            Start-Sleep -Seconds 10
            $service | Start-Service
            $serverservice = "Running, Restarted"
        }
        else 
        {
            $service | start-service
            $serverservice = "Stopped, Started"
        }
    }
}

Append-Log ( $env:COMPUTERNAME + ", " + $DVR + ", " + $adminservice + $configservice + $serverservice )

