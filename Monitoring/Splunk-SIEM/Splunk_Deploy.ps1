<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 07/13/2017
    Organization: Domain, Inc.
    Filename: Splunk_Deploy.ps1
    =========================================================
    .DESCRIPTION
        Installs and sets up Splunk on target devices

    .VERSION INFO
        v1 - initial script build
#>

$ErrorActionPreference = "silentlycontinue"

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = get-date -Format s | foreach {$_ -replace ":", "."}
$Script:Logfile = "C:\temp\Splunk_Deploy_$stamp.txt"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "Computer, Install Status, Service Status"
function Append-Log($message)
{
	Add-Content $Script:LogFile "$message"
}

# ----------------------------------------------------------------------------------------------
# Functions

function Install-Splunk($computer)
{
    $filepath = "\\$computer\C$\...\splunk"
    $msipath = "\\$computer\C$\...\splunkforwarder-6.4.8-5dedc6298537-x64-release.msi"
    $confpath = "\\$computer\C$\...\deploymentclient.conf"
    $batpath = "\\$computer\C$\...\splunk-PsExecInstallScript.bat"
    
    if(!(Test-Path $filepath))
    {
        New-Item -Path $filepath -ItemType Directory -Force
    }
    if(!(Test-Path $msipath))
    {
        Copy-Item "\\SERVER\SHARE\...\splunkforwarder-6.4.8-5dedc6298537-x64-release.msi" $msipath -force
    }
    Copy-Item "\\SERVER\SHARE\...\splunk_deploymentclient.conf" $confpath -Force
    Copy-Item "\\SERVER\SHARE\...\splunk_PsExecInstallScript.bat" $batpath -Force
    Invoke-Command -ComputerName $computer -ScriptBlock{
        Start-Process -FilePath "C:\software\splunk\splunk-PsExecInstallScript.bat" -Wait
        #Start-Process msiexec.exe -ArgumentList $args -Wait
        Start-Sleep -Seconds 600
        Copy-Item "c:\software\splunk\deploymentclient.conf" "C:\Program Files\SplunkUniversalForwarder\etc\system\local\deploymentclient.conf" -Force
        Get-Service -Name SplunkForwarder | Start-Service
    }
}

# ----------------------------------------------------------------------------------------------
# Variables

#$computers = (Get-ADComputer -SearchBase "ou=store jumpstart computers,ou=store computers,dc=domain,dc=com" -Filter *).Name
$computers = get-content C:\temp\computers.txt
#$computers = Read-Host "Enter Computer Name"

# ----------------------------------------------------------------------------------------------
# Script

foreach($computer in $computers)
{
    $splunkcheck = Get-Service -ComputerName $computer -Name SplunkForwarder
    if($splunkcheck -eq $true)
    {
        get-service -ComputerName $computer -name SplunkForwarder | Restart-Service
        Append-Log "$computer, already installed, Service Restarted"
        continue
    }
    else 
    {
        Install-Splunk $computer
        $servicecheck = (Get-Service -ComputerName $computer -Name splunkforwarder).Status
        if($servicecheck -eq "Running")
        {
            Append-Log "$computer, Installed, Running"
        }
        else 
        {
            Append-Log "$computer, Installed, Not Running"
        }
    }
}