# Blueprinting Script for Server Documentation

# Create output folder; Validate if exists; If not exist, create it
$OutputFolder = "C:\Blueprint"
if (-Not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder }

# System Overview
Get-WmiObject Win32_OperatingSystem | Select-Object Caption, OSArchitecture, Version, BuildNumber | Out-File "$OutputFolder\system_info.txt"
Get-WmiObject Win32_ComputerSystem | Select-Object Manufacturer, Model, TotalPhysicalMemory | Out-File "$OutputFolder\hardware_info.txt"
ipconfig /all > "$OutputFolder\network_config.txt"

# Installed Applications
Get-WmiObject Win32_Product | Select-Object Name, Version, Vendor | Out-File "$OutputFolder\installed_apps.txt"
reg export HKEY_LOCAL_MACHINE\SOFTWARE "$OutputFolder\software_registry_backup.reg"

# Database Details
Get-Service | Where-Object { $_.DisplayName -like '*SQL*' -or $_.DisplayName -like '*Database*' } | Out-File "$OutputFolder\database_services.txt"
sqlcmd -L > "$OutputFolder\sql_instances.txt"

# Services and Scheduled Tasks
Get-Service | Select-Object DisplayName, Status, StartType, DependentServices | Out-File "$OutputFolder\services_list.txt"
schtasks /query /FO LIST /V > "$OutputFolder\scheduled_tasks.txt"

# Security and Credentials
Get-LocalUser | Select-Object Name, Enabled | Out-File "$OutputFolder\local_users.txt"
Get-LocalGroup | Select-Object Name | Out-File "$OutputFolder\local_groups.txt"
gpresult /H "$OutputFolder\gp_report.html"

# IIS Configurations
appcmd list site /config /xml > "$OutputFolder\iis_sites.xml"

Write-Output "Blueprinting Complete. Output saved to $OutputFolder"
