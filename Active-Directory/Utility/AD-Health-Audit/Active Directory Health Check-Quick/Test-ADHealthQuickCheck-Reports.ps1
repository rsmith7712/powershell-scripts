#Requires -RunAsAdministrator
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
    Test-ADHealthQuickCheck-Reports.ps1

.SYNOPSIS
    Performs a quick Active Directory health spot-check and exports transcript, CSV, and HTML results.

.DESCRIPTION
    This script runs a concise set of common AD health checks, including:
      - repadmin replication summary
      - required service status checks on a target server
      - dcdiag DNS tests
      - LDAP signing-related event log checks

    In addition to console output, the script writes:
      - a transcript (.txt)
      - a structured CSV for service and event results
      - an HTML report for easy review

    This public-safe version uses placeholders and avoids environment-specific values.

    .NOTES
        Replace placeholder values before production use.

    .PARAMETER Server
        Target domain controller to query for service status and DCDiag DNS tests.

    .PARAMETER OutputDirectory
        Directory where report files will be written.

    .PARAMETER EventIds
        Directory Service event IDs to include in the LDAP-related event review.

    .EXAMPLE
        .\Test-ADHealthQuickCheck-Reports.ps1 -Server DC01 -OutputDirectory C:\Reports

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Server,

    [Parameter()]
    [string]$OutputDirectory = 'C:\Reports',

    [Parameter()]
    [int[]]$EventIds = @(2886, 2887, 2889)
)

Import-Module ActiveDirectory -ErrorAction Stop

if (-not (Test-Path -LiteralPath $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
}

$timestamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$transcriptPath = Join-Path $OutputDirectory "ADHealthQuickCheck_$timestamp.txt"
$serviceCsvPath = Join-Path $OutputDirectory "ADHealthQuickCheck_Services_$timestamp.csv"
$eventCsvPath = Join-Path $OutputDirectory "ADHealthQuickCheck_Events_$timestamp.csv"
$htmlPath = Join-Path $OutputDirectory "ADHealthQuickCheck_$timestamp.html"

$services = @(
    'DNS',
    'DFSR',
    'IsmServ',
    'Kdc',
    'Netlogon',
    'NTDS'
)

$serviceResults = @()
$eventResults = @()
$repadminText = @()
$dcdiagText = @()

Start-Transcript -Path $transcriptPath -Force | Out-Null

try {
    Write-Host '=== Active Directory Health Quick Check ===' -ForegroundColor Cyan
    Write-Host "Target server: $Server" -ForegroundColor Cyan
    Write-Host "Run time: $(Get-Date)" -ForegroundColor Cyan

    Write-Host "`n--- Replication Summary ---" -ForegroundColor Yellow
    $repadminText = repadmin /replsum 2>&1
    $repadminText | ForEach-Object { $_ }

    Write-Host "`n--- Critical AD-Related Services ---" -ForegroundColor Yellow
    foreach ($serviceName in $services) {
        $service = Get-Service -ComputerName $Server -Name $serviceName -ErrorAction SilentlyContinue
        if ($null -eq $service) {
            $result = [pscustomobject]@{
                Server        = $Server
                ServiceName   = $serviceName
                DisplayName   = $null
                Status        = 'NotFound'
                StartType     = $null
                CheckedAt     = Get-Date
            }
            Write-Host "$serviceName was not found on $Server" -ForegroundColor DarkYellow
        }
        else {
            $result = [pscustomobject]@{
                Server        = $Server
                ServiceName   = $service.Name
                DisplayName   = $service.DisplayName
                Status        = [string]$service.Status
                StartType     = $service.StartType
                CheckedAt     = Get-Date
            }

            if ($service.Status -eq 'Running') {
                Write-Host "$($service.Name) is running on $Server" -ForegroundColor Green
            }
            else {
                Write-Host "$($service.Name) is $($service.Status) on $Server" -ForegroundColor Red
            }
        }

        $serviceResults += $result
    }

    Write-Host "`n--- DCDiag DNS Test ---" -ForegroundColor Yellow
    $dcdiagText = dcdiag /test:DNS /s:$Server /e /v 2>&1
    $dcdiagText | ForEach-Object { $_ }

    Write-Host "`n--- LDAP Signing / Bind Events ---" -ForegroundColor Yellow
    Write-Host "Checking Directory Service log for LDAP-related events $($EventIds -join ', ')." -ForegroundColor Gray

    $eventResults = @(Get-WinEvent -FilterHashtable @{
        LogName = 'Directory Service'
        Id      = $EventIds
    } -ErrorAction SilentlyContinue |
        Select-Object @{
                Name = 'Server'; Expression = { $Server }
            },
            TimeCreated,
            Id,
            LevelDisplayName,
            ProviderName,
            MachineName,
            Message)

    if ($eventResults.Count -gt 0) {
        $eventResults | Format-Table TimeCreated, Id, LevelDisplayName, ProviderName -AutoSize
    }
    else {
        Write-Host 'No matching LDAP-related events were returned from the Directory Service log.' -ForegroundColor Green
    }

    $serviceResults | Export-Csv -Path $serviceCsvPath -NoTypeInformation -Encoding UTF8
    $eventResults   | Export-Csv -Path $eventCsvPath -NoTypeInformation -Encoding UTF8

    $summary = [pscustomobject]@{
        Server               = $Server
        RunTime              = Get-Date
        ServicesChecked      = $serviceResults.Count
        ServicesNotRunning   = ($serviceResults | Where-Object { $_.Status -ne 'Running' }).Count
        EventIdsQueried      = ($EventIds -join ', ')
        MatchingEvents       = $eventResults.Count
        TranscriptPath       = $transcriptPath
        ServiceCsvPath       = $serviceCsvPath
        EventCsvPath         = $eventCsvPath
    }

    $summaryHtml = $summary | ConvertTo-Html -Fragment -PreContent '<h2>Summary</h2>'
    $servicesHtml = $serviceResults | ConvertTo-Html -Fragment -PreContent '<h2>Service Status</h2>'
    $eventsHtml = if ($eventResults.Count -gt 0) {
        $eventResults | Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, MachineName, Message |
            ConvertTo-Html -Fragment -PreContent '<h2>LDAP-Related Events</h2>'
    }
    else {
        '<h2>LDAP-Related Events</h2><p>No matching events were returned.</p>'
    }

    $repadminHtml = "<h2>repadmin /replsum</h2><pre>$([System.Web.HttpUtility]::HtmlEncode(($repadminText -join [Environment]::NewLine)))</pre>"
    $dcdiagHtml = "<h2>dcdiag /test:DNS</h2><pre>$([System.Web.HttpUtility]::HtmlEncode(($dcdiagText -join [Environment]::NewLine)))</pre>"

    $htmlBody = @"
<h1>Active Directory Health Quick Check</h1>
<p><strong>Target server:</strong> $Server</p>
<p><strong>Generated:</strong> $(Get-Date)</p>
$summaryHtml
$servicesHtml
$eventsHtml
$repadminHtml
$dcdiagHtml
"@

    ConvertTo-Html -Title "AD Health Quick Check - $Server" -Body $htmlBody |
        Out-File -FilePath $htmlPath -Encoding UTF8

    Write-Host "`nReports written:" -ForegroundColor Cyan
    Write-Host " - Transcript: $transcriptPath" -ForegroundColor Cyan
    Write-Host " - Services CSV: $serviceCsvPath" -ForegroundColor Cyan
    Write-Host " - Events CSV: $eventCsvPath" -ForegroundColor Cyan
    Write-Host " - HTML: $htmlPath" -ForegroundColor Cyan
}
finally {
    Stop-Transcript | Out-Null
}
