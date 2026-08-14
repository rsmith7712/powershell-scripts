# LEGAL
<# LICENSE
    MIT License, Copyright 2026 Richard Smith

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
   - Install_All_Remote_Server_Admin_Pkgs.ps1

.DESCRIPTION
    TBD

.FUNCTIONALITY
    Production-Safer Version with:
    -Admin check
    -OS check
    -Feature existence validation
    -Optional .NET 3.5 source path
    -Logging
    - -WhatIf support
    -Clean handling of unsupported features like WSL on some server builds

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$NetFx3Source = "",
    [string]$LogPath = "C:\Temp\Logs\FeatureInstall_{0}.log" -f (Get-Date -Format 'yyyy-MM-dd_HHmmss')
)

# Ensure log folder exists
$logFolder = Split-Path -Path $LogPath -Parent
if (-not (Test-Path -Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $entry = "$timestamp [$Level] $Message"
    Write-Host $entry
    Add-Content -Path $LogPath -Value $entry
}

function Test-IsAdministrator {
    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-ServerFeatureSafe {
    param(
        [Parameter(Mandatory)]
        [string]$FeatureName,

        [string]$DisplayName = $FeatureName,

        [switch]$IncludeAllSubFeature,
        [switch]$IncludeManagementTools,
        [string]$Source
    )

    $feature = Get-WindowsFeature -Name $FeatureName -ErrorAction SilentlyContinue

    if (-not $feature) {
        Write-Log "Feature not found on this server build: $FeatureName ($DisplayName). Skipping." "WARN"
        return
    }

    if ($feature.Installed) {
        Write-Log "Already installed: $FeatureName ($DisplayName)"
        return
    }

    $params = @{
        Name        = $FeatureName
        ErrorAction = 'Stop'
    }

    if ($IncludeAllSubFeature)   { $params.IncludeAllSubFeature   = $true }
    if ($IncludeManagementTools) { $params.IncludeManagementTools = $true }
    if ($Source)                 { $params.Source                 = $Source }

    try {
        if ($PSCmdlet.ShouldProcess($FeatureName, "Install Windows Feature")) {
            Write-Log "Installing: $FeatureName ($DisplayName)"
            $result = Install-WindowsFeature @params

            if ($result.Success) {
                Write-Log "Install successful: $FeatureName ($DisplayName)"
                if ($result.RestartNeeded -and $result.RestartNeeded -ne 'No') {
                    Write-Log "Restart required for: $FeatureName ($DisplayName). RestartNeeded=$($result.RestartNeeded)" "WARN"
                }
            }
            else {
                Write-Log "Install returned unsuccessful result for: $FeatureName ($DisplayName)" "ERROR"
            }
        }
    }
    catch {
        Write-Log "Install failed for $FeatureName ($DisplayName): $($_.Exception.Message)" "ERROR"
    }
}

# Start
Write-Log "----- Script started -----"

if (-not (Test-IsAdministrator)) {
    Write-Log "This script must be run in an elevated PowerShell session." "ERROR"
    throw "Run PowerShell as Administrator."
}

$os = Get-CimInstance Win32_OperatingSystem
Write-Log "Computer: $env:COMPUTERNAME"
Write-Log "OS: $($os.Caption) $($os.Version)"
Write-Log "Log file: $LogPath"

if (-not (Get-Command Get-WindowsFeature -ErrorAction SilentlyContinue)) {
    Write-Log "Get-WindowsFeature is not available. This script is intended for Windows Server with ServerManager module." "ERROR"
    throw "ServerManager module/cmdlets not available."
}

# Target features
$features = @(
    @{
        Name = 'RSAT'
        DisplayName = 'Remote Server Administration Tools'
        IncludeAllSubFeature = $true
    },
    @{
        Name = 'Failover-Clustering'
        DisplayName = 'Failover Clustering'
        IncludeManagementTools = $true
    },
    @{
        Name = 'GPMC'
        DisplayName = 'Group Policy Management'
    },
    @{
        Name = 'CMAK'
        DisplayName = 'Connection Manager Administration Kit'
    },
    @{
        Name = 'System-Insights'
        DisplayName = 'System Insights'
    },
    @{
        Name = 'PowerShell-V2'
        DisplayName = 'Windows PowerShell 2.0 Engine'
    },
    @{
        Name = 'PowerShell-ISE'
        DisplayName = 'Windows PowerShell ISE'
    },
    @{
        Name = 'Migration'
        DisplayName = 'Windows Server Migration Tools'
    },
    @{
        Name = 'WindowsStorageManagementService'
        DisplayName = 'Windows Standards-Based Storage Management'
    }
)

# Install standard features
foreach ($item in $features) {
    Install-ServerFeatureSafe `
        -FeatureName $item.Name `
        -DisplayName $item.DisplayName `
        -IncludeAllSubFeature:([bool]$item.IncludeAllSubFeature) `
        -IncludeManagementTools:([bool]$item.IncludeManagementTools)
}

# Install .NET Framework 3.5
try {
    $netfx = Get-WindowsFeature -Name NET-Framework-Core -ErrorAction SilentlyContinue
    if ($netfx) {
        if ($netfx.Installed) {
            Write-Log ".NET Framework 3.5 already installed."
        }
        else {
            if ([string]::IsNullOrWhiteSpace($NetFx3Source)) {
                Write-Log "Installing .NET Framework 3.5 without explicit source path."
                Install-ServerFeatureSafe -FeatureName 'NET-Framework-Core' -DisplayName '.NET Framework 3.5'
            }
            else {
                Write-Log "Installing .NET Framework 3.5 using source: $NetFx3Source"
                Install-ServerFeatureSafe -FeatureName 'NET-Framework-Core' -DisplayName '.NET Framework 3.5' -Source $NetFx3Source
            }
        }
    }
    else {
        Write-Log "NET-Framework-Core not found on this server build." "WARN"
    }
}
catch {
    Write-Log "Error while processing .NET Framework 3.5: $($_.Exception.Message)" "ERROR"
}

# Attempt WSL detection safely
try {
    $linuxFeatures = Get-WindowsFeature *Linux* -ErrorAction SilentlyContinue
    if ($linuxFeatures) {
        Write-Log "Linux-related server features detected:"
        foreach ($lf in $linuxFeatures) {
            Write-Log " - $($lf.Name) [$($lf.InstallState)]"
        }
    }
    else {
        Write-Log "No Linux-related features exposed through Get-WindowsFeature on this server build." "WARN"
    }
}
catch {
    Write-Log "Unable to query Linux-related features: $($_.Exception.Message)" "WARN"
}

# Update help
try {
    if ($PSCmdlet.ShouldProcess("PowerShell Help", "Update help content")) {
        Write-Log "Running Update-Help"
        Update-Help -ErrorAction Stop
        Write-Log "Update-Help completed successfully."
    }
}
catch {
    Write-Log "Update-Help failed: $($_.Exception.Message)" "WARN"
}

Write-Log "----- Script completed -----"