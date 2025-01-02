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
    Achieve a complete blueprint of an inherited server.

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
$LogFile = "$OutputFolder\blueprint_log.txt"

# Initialize Logging Function
function Write-Log {
    param (
        [string]$Message,
        [string]$Type = "INFO"
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Type] $Message"
    Add-Content -Path $LogFile -Value $LogMessage
}

# Ensure Output Folder Exists
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
    Get-WmiObject Win32_OperatingSystem | Select-Object Caption, OSArchitecture, Version, BuildNumber | Out-File "$OutputFolder\system_info.txt"
    Write-Log -Message "System overview saved to system_info.txt."
}
catch {
    Write-Log -Message "Failed to gather system overview: $_" -Type "ERROR"
}

try {
    Get-WmiObject Win32_ComputerSystem | Select-Object Manufacturer, Model, TotalPhysicalMemory | Out-File "$OutputFolder\hardware_info.txt"
    Write-Log -Message "Hardware information saved to hardware_info.txt."
}
catch {
    Write-Log -Message "Failed to gather hardware information: $_" -Type "ERROR"
}

try {
    ipconfig /all > "$OutputFolder\network_config.txt"
    Write-Log -Message "Network configuration saved to network_config.txt."
}
catch {
    Write-Log -Message "Failed to gather network configuration: $_" -Type "ERROR"
}

# Installed Applications
try {
    Get-WmiObject Win32_Product | Select-Object Name, Version, Vendor | Out-File "$OutputFolder\installed_apps.txt"
    Write-Log -Message "Installed applications saved to installed_apps.txt."
}
catch {
    Write-Log -Message "Failed to gather installed applications: $_" -Type "ERROR"
}

try {
    reg export HKEY_LOCAL_MACHINE\SOFTWARE "$OutputFolder\software_registry_backup.reg"
    Write-Log -Message "Registry backup saved to software_registry_backup.reg."
}
catch {
    Write-Log -Message "Failed to export registry: $_" -Type "ERROR"
}

# Database Details
try {
    Get-Service | Where-Object { $_.DisplayName -like '*SQL*' -or $_.DisplayName -like '*Database*' } | Out-File "$OutputFolder\database_services.txt"
    Write-Log -Message "Database services saved to database_services.txt."
}
catch {
    Write-Log -Message "Failed to gather database services: $_" -Type "ERROR"
}

try {
    sqlcmd -L > "$OutputFolder\sql_instances.txt"
    Write-Log -Message "SQL instances saved to sql_instances.txt."
}
catch {
    Write-Log -Message "Failed to gather SQL instances: $_" -Type "ERROR"
}

# Services and Scheduled Tasks
try {
    Get-Service | Select-Object DisplayName, Status, StartType, DependentServices | Out-File "$OutputFolder\services_list.txt"
    Write-Log -Message "Services list saved to services_list.txt."
}
catch {
    Write-Log -Message "Failed to gather services list: $_" -Type "ERROR"
}

try {
    schtasks /query /FO LIST /V > "$OutputFolder\scheduled_tasks.txt"
    Write-Log -Message "Scheduled tasks saved to scheduled_tasks.txt."
}
catch {
    Write-Log -Message "Failed to gather scheduled tasks: $_" -Type "ERROR"
}

# Security and Credentials
try {
    Get-LocalUser | Select-Object Name, Enabled | Out-File "$OutputFolder\local_users.txt"
    Write-Log -Message "Local users saved to local_users.txt."
}
catch {
    Write-Log -Message "Failed to gather local users: $_" -Type "ERROR"
}

try {
    Get-LocalGroup | Select-Object Name | Out-File "$OutputFolder\local_groups.txt"
    Write-Log -Message "Local groups saved to local_groups.txt."
}
catch {
    Write-Log -Message "Failed to gather local groups: $_" -Type "ERROR"
}

try {
    gpresult /H "$OutputFolder\gp_report.html"
    Write-Log -Message "Group policy report saved to gp_report.html."
}
catch {
    Write-Log -Message "Failed to generate group policy report: $_" -Type "ERROR"
}

# IIS Configurations
try {
    appcmd list site /config /xml > "$OutputFolder\iis_sites.xml"
    Write-Log -Message "IIS configurations saved to iis_sites.xml."
}
catch {
    Write-Log -Message "Failed to gather IIS configurations: $_" -Type "ERROR"
}

Write-Log -Message "Blueprinting Complete. Output saved to $OutputFolder."
