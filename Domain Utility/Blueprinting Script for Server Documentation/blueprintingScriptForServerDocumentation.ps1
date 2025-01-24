# LEGAL
<# LICENSE
    MIT License, Copyright 2025 Richard Smith

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the “Software”),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    IN THE SOFTWARE.
#>
# GENERAL SCRIPT INFORMATION
<#
.NAME
    blueprintingScriptForServerDocumentation.ps1

.SYNOPSIS
    Blueprinting Script for Server Documentation with Logging and Remote Capability
    with GUI and Console Options

.FUNCTIONALITY
    Run the Script: 
        - Execute the script on the inherited system with administrative privileges.
    Review Output:
        - Inspect the generated files in C:\Blueprint for completeness.
    Plan Migration:
        - Use the detailed blueprint to replicate configurations on the new server.
.NOTES

#>

# Create output folder
$OutputFolder = "C:\Blueprint"
$RemoteReportsFolder = "$OutputFolder\Remote-Reports"
$LogFile = "$OutputFolder\blueprint_log.txt"

# Initialize Logging Function
function Write-Log {
    param (
        [string]$Message,
        [string]$Type = "INFO"
    )
    # Ensure log file path exists
    if (-Not (Test-Path (Split-Path -Path $LogFile))) {
        New-Item -ItemType Directory -Path (Split-Path -Path $LogFile) -Force
    }
    if (-Not (Test-Path $LogFile)) {
        New-Item -ItemType File -Path $LogFile -Force
    }
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Type] $Message"
    Add-Content -Path $LogFile -Value $LogMessage
}

# Check if running as administrator
function Check-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (-not $isAdmin) {
        Write-Host "This script must be run as an Administrator. Relaunching..." -ForegroundColor Red
        Write-Log -Message "Script was not run as Administrator. Relaunching." -Type "ERROR"
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -WindowStyle Hidden" -Verb RunAs
        exit
    }
}

Check-Admin

# Execute command function
function Execute-Command {
    param (
        [string]$ComputerName,
        [ScriptBlock]$Command
    )
    if ($ComputerName -eq "localhost") {
        Invoke-Command -ScriptBlock $Command
    }
    else {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock $Command
    }
}

# Core logic for blueprinting
function Run-Blueprinting {
    param (
        [string]$ExecutionMode,
        [string]$RemoteComputer = ""
    )
    $TargetComputer = if ($ExecutionMode -eq "Remote") { $RemoteComputer } else { "localhost" }
    Write-Log -Message "Starting blueprinting process. Execution Mode: $ExecutionMode."
    Write-Host "Starting blueprinting process in $ExecutionMode Mode..." -ForegroundColor Green

    if (-Not (Test-Path $OutputFolder)) {
        try {
            New-Item -ItemType Directory -Path $OutputFolder -Force
            Write-Log -Message "Created output folder at $OutputFolder."
        }
        catch {
            Write-Log -Message "Failed to create output folder: $_" -Type "ERROR"
            throw
        }
    }
    else {
        Write-Log -Message "Output folder already exists at $OutputFolder."
    }

    # System Overview
    try {
        Execute-Command -ComputerName $TargetComputer -Command {
            Get-WmiObject Win32_OperatingSystem | Select-Object Caption, OSArchitecture, Version, BuildNumber
        } | Out-File "$OutputFolder\system_info.txt"
        Write-Log -Message "System overview saved to system_info.txt."
    }
    catch {
        Write-Log -Message "Failed to gather system overview: $_" -Type "ERROR"
    }

    try {
        Execute-Command -ComputerName $TargetComputer -Command {
            Get-WmiObject Win32_ComputerSystem | Select-Object Manufacturer, Model, TotalPhysicalMemory
        } | Out-File "$OutputFolder\hardware_info.txt"
        Write-Log -Message "Hardware information saved to hardware_info.txt."
    }
    catch {
        Write-Log -Message "Failed to gather hardware information: $_" -Type "ERROR"
    }

    try {
        if ($TargetComputer -eq "localhost") {
            ipconfig /all > "$OutputFolder\network_config.txt"
        }
        else {
            Execute-Command -ComputerName $TargetComputer -Command {
                ipconfig /all
            } > "$OutputFolder\network_config.txt"
        }
        Write-Log -Message "Network configuration saved to network_config.txt."
    }
    catch {
        Write-Log -Message "Failed to gather network configuration: $_" -Type "ERROR"
    }

    # Installed Applications
    try {
        Execute-Command -ComputerName $TargetComputer -Command {
            Get-WmiObject Win32_Product | Select-Object Name, Version, Vendor
        } | Out-File "$OutputFolder\installed_apps.txt"
        Write-Log -Message "Installed applications saved to installed_apps.txt."
    }
    catch {
        Write-Log -Message "Failed to gather installed applications: $_" -Type "ERROR"
    }

    try {
        Execute-Command -ComputerName $TargetComputer -Command {
            reg export HKEY_LOCAL_MACHINE\SOFTWARE "$OutputFolder\software_registry_backup.reg"
        }
        Write-Log -Message "Registry backup saved to software_registry_backup.reg."
    }
    catch {
        Write-Log -Message "Failed to export registry: $_" -Type "ERROR"
    }

    # Database Details
    try {
        Execute-Command -ComputerName $TargetComputer -Command {
            Get-Service | Where-Object { $_.DisplayName -like '*SQL*' -or $_.DisplayName -like '*Database*' }
        } | Out-File "$OutputFolder\database_services.txt"
        Write-Log -Message "Database services saved to database_services.txt."
    }
    catch {
        Write-Log -Message "Failed to gather database services: $_" -Type "ERROR"
    }

    try {
        if ($TargetComputer -eq "localhost") {
            sqlcmd -L > "$OutputFolder\sql_instances.txt"
        }
        else {
            Execute-Command -ComputerName $TargetComputer -Command {
                sqlcmd -L
            } > "$OutputFolder\sql_instances.txt"
        }
        Write-Log -Message "SQL instances saved to sql_instances.txt."
    }
    catch {
        Write-Log -Message "Failed to gather SQL instances: $_" -Type "ERROR"
    }

    # Services and Scheduled Tasks
    try {
        Execute-Command -ComputerName $TargetComputer -Command {
            Get-Service | Select-Object DisplayName, Status, StartType, DependentServices
        } | Out-File "$OutputFolder\services_list.txt"
        Write-Log -Message "Services list saved to services_list.txt."
    }
    catch {
        Write-Log -Message "Failed to gather services list: $_" -Type "ERROR"
    }

    try {
        if ($TargetComputer -eq "localhost") {
            schtasks /query /FO LIST /V > "$OutputFolder\scheduled_tasks.txt"
        }
        else {
            Execute-Command -ComputerName $TargetComputer -Command {
                schtasks /query /FO LIST /V
            } > "$OutputFolder\scheduled_tasks.txt"
        }
        Write-Log -Message "Scheduled tasks saved to scheduled_tasks.txt."
    }
    catch {
        Write-Log -Message "Failed to gather scheduled tasks: $_" -Type "ERROR"
    }

    # Security and Credentials
    try {
        Execute-Command -ComputerName $TargetComputer -Command {
            Get-LocalUser | Select-Object Name, Enabled
        } | Out-File "$OutputFolder\local_users.txt"
        Write-Log -Message "Local users saved to local_users.txt."
    }
    catch {
        Write-Log -Message "Failed to gather local users: $_" -Type "ERROR"
    }

    try {
        Execute-Command -ComputerName $TargetComputer -Command {
            Get-LocalGroup | Select-Object Name
        } | Out-File "$OutputFolder\local_groups.txt"
        Write-Log -Message "Local groups saved to local_groups.txt."
    }
    catch {
        Write-Log -Message "Failed to gather local groups: $_" -Type "ERROR"
    }

    try {
        if ($TargetComputer -eq "localhost") {
            gpresult /H "$OutputFolder\gp_report.html"
        }
        else {
            Execute-Command -ComputerName $TargetComputer -Command {
                gpresult /H "$OutputFolder\gp_report.html"
            }
        }
        Write-Log -Message "Group policy report saved to gp_report.html."
    }
    catch {
        Write-Log -Message "Failed to generate group policy report: $_" -Type "ERROR"
    }

    # IIS Configurations
    try {
        Execute-Command -ComputerName $TargetComputer -Command {
            appcmd list site /config /xml
        } | Out-File "$OutputFolder\iis_sites.xml"
        Write-Log -Message "IIS configurations saved to iis_sites.xml."
    }
    catch {
        Write-Log -Message "Failed to gather IIS configurations: $_" -Type "ERROR"
    }

    Write-Log -Message "Blueprinting process completed."
    Write-Host "Blueprinting process completed." -ForegroundColor Green
}

# Prompt for console or GUI mode
Write-Host "Select Interface Mode:" -ForegroundColor Green
Write-Host "1. Console Mode" -ForegroundColor Yellow
Write-Host "2. Graphical Interface (GUI)" -ForegroundColor Yellow
$InterfaceMode = Read-Host "Enter choice (1 or 2)"

if ($InterfaceMode -eq "2") {
    # Load WPF Assembly
    Add-Type -AssemblyName PresentationFramework

    # Create WPF GUI
    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Server Blueprinting Tool" Height="400" Width="600">
    <Grid>
        <TextBlock Text="Select Execution Mode:" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="10,10,0,0"/>
        <RadioButton x:Name="LocalMode" Content="Local" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="150,10,0,0" IsChecked="True"/>
        <RadioButton x:Name="RemoteMode" Content="Remote" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="230,10,0,0"/>
        <TextBox x:Name="RemoteComputerBox" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="150,40,0,0" Width="200" IsEnabled="False"/>
        <Button Content="Start" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="10,80,0,0" Width="100" x:Name="StartButton"/>
        <TextBox x:Name="LogsBox" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="10,120,0,0" Width="560" Height="200" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto"/>
    </Grid>
</Window>
"@

    # Load XAML
    $reader = (New-Object System.Xml.XmlNodeReader (New-Object System.Xml.XmlDocument)).ReadOuterXml()
    $reader.ReadInnerXml($xaml)
    $Window = [System.Windows.Markup.XamlReader]::Load($reader)

    # GUI Event Handlers
    $Window.FindName("RemoteMode").Add_CheckedChanged({
            $Window.FindName("RemoteComputerBox").IsEnabled = $true
        })

    $Window.FindName("LocalMode").Add_CheckedChanged({
            $Window.FindName("RemoteComputerBox").IsEnabled = $false
        })

    $Window.FindName("StartButton").Add_Click({
            $ExecutionMode = if ($Window.FindName("LocalMode").IsChecked) { "Local" } else { "Remote" }
            $RemoteComputer = $Window.FindName("RemoteComputerBox").Text
            $LogsBox = $Window.FindName("LogsBox")
            $LogsBox.AppendText("Execution Mode: $ExecutionMode`n")
            if ($ExecutionMode -eq "Remote") {
                $LogsBox.AppendText("Remote Computer: $RemoteComputer`n")
            }
            Run-Blueprinting -ExecutionMode $ExecutionMode -RemoteComputer $RemoteComputer
            $LogsBox.AppendText("Blueprinting process completed.`n")
        })

    # Show the Window
    $Window.ShowDialog() | Out-Null
    exit
}

# If Console Mode is selected, proceed with interactive prompt
Write-Host "Proceeding in Console Mode..." -ForegroundColor Green
Write-Host "Select Execution Mode:" -ForegroundColor Green
Write-Host "1. Local" -ForegroundColor Yellow
Write-Host "2. Remote" -ForegroundColor Yellow
$ExecutionModeInput = Read-Host "Enter choice (1 or 2)"
if ($ExecutionModeInput -eq "2") {
    $RemoteComputer = Read-Host "Enter the remote computer name or IPv4 address"
    Run-Blueprinting -ExecutionMode "Remote" -RemoteComputer $RemoteComputer
}
else {
    Run-Blueprinting -ExecutionMode "Local"
}