#requires -Version 5.1
# LEGAL
<# LICENSE
    MIT License, Copyright 2016 Richard Smith

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
    BackPressure.v2.ps1

.SYNOPSIS
    Checks Exchange transport servers for back pressure events

.DESCRIPTION
    fixed the malformed dash characters that would break Invoke-Command
    switched from Get-EventLog to Get-WinEvent
    cleaned up variable naming so input parameters are not reused in loops
    added support for one or many servers with clearer parameter handling
    added optional CSV export with -ReportPath
    added optional event message capture with -IncludeEventDetails

    Recommended example run:
    .\BackPressure.v2.ps1 -Server EXAMPLE-EX01 -Verbose

    Export example:
    .\BackPressure.v2.ps1 -Server EXAMPLE-EX01,EXAMPLE-EX02 -ReportPath .\Reports\BackPressureReport.csv -Verbose

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, Position = 0)]
    [string[]]$Server,

    [Parameter(Mandatory = $false)]
    [string]$Role = 'HubTransport',

    [Parameter(Mandatory = $false)]
    [int]$MaxEvents = 200,

    [Parameter(Mandatory = $false)]
    [string]$ReportPath,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeEventDetails
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Import-ExchangeManagement {
    [CmdletBinding()]
    param()

    $snapInName = 'Microsoft.Exchange.Management.PowerShell.E2010'

    if (-not (Get-PSSnapin -Name $snapInName -ErrorAction SilentlyContinue)) {
        try {
            Add-PSSnapin -Name $snapInName -ErrorAction Stop
            Write-Verbose "Loaded Exchange snap-in: $snapInName"
        }
        catch {
            throw "Unable to load Exchange 2010 management snap-in '$snapInName'. Run this from an Exchange Management Shell or a workstation/server with the Exchange 2010 management tools installed. $($_.Exception.Message)"
        }
    }
}

function Get-TargetExchangeServers {
    [CmdletBinding()]
    param(
        [string[]]$Server,
        [string]$Role
    )

    if ($Server) {
        $resolved = foreach ($ServerName in $Server) {
            try {
                Get-ExchangeServer -Identity $ServerName -ErrorAction Stop
            }
            catch {
                throw "Exchange server '$ServerName' could not be resolved. $($_.Exception.Message)"
            }
        }

        return @($resolved)
    }

    $allServers = @(Get-ExchangeServer)

    switch ($Role) {
        'HubTransport' {
            return @($allServers | Where-Object { $_.IsHubTransportServer })
        }
        'All' {
            return $allServers
        }
        default {
            throw "Unsupported role filter '$Role'. Valid values are 'HubTransport' or 'All'."
        }
    }
}

function Get-BackPressureState {
    [CmdletBinding()]
    param(
        [int]$EventId,
        [object[]]$ReplacementStrings
    )

    switch ($EventId) {
        15006 { return 'Critical (Disk Space)' }
        15007 { return 'Critical (Memory)' }
        default {
            if ($ReplacementStrings -and $ReplacementStrings.Count -ge 2 -and $ReplacementStrings[1]) {
                return [string]$ReplacementStrings[1]
            }

            return 'Detected (Unknown State)'
        }
    }
}

function Get-BackPressureEvents {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        [Parameter(Mandatory = $false)]
        [int]$MaxEvents = 200
    )

    $filterHashtable = @{
        LogName      = 'Application'
        ProviderName = 'MSExchangeTransport'
        StartTime    = (Get-Date).AddYears(-5)
        Id           = 15004, 15005, 15006, 15007
    }

    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        param($RemoteFilterHashtable, $RemoteMaxEvents)

        Get-WinEvent -FilterHashtable $RemoteFilterHashtable -MaxEvents $RemoteMaxEvents -ErrorAction Stop |
            Where-Object {
                $_.ProviderName -eq 'MSExchangeTransport' -and
                $_.LevelDisplayName -in @('Warning', 'Error', 'Critical', 'Information')
            } |
            Sort-Object TimeCreated -Descending
    } -ArgumentList $filterHashtable, $MaxEvents
}

Import-ExchangeManagement
$exchangeServers = @(Get-TargetExchangeServers -Server $Server -Role $Role)

if (-not $exchangeServers -or $exchangeServers.Count -eq 0) {
    throw 'No Exchange servers matched the selection criteria.'
}

$results = foreach ($ExchangeServer in $exchangeServers) {
    $computerName = if ($ExchangeServer.Name) { $ExchangeServer.Name } else { [string]$ExchangeServer }
    Write-Verbose "Checking $computerName for Exchange transport back pressure events."

    try {
        $events = @(Get-BackPressureEvents -ComputerName $computerName -MaxEvents $MaxEvents)

        if ($events.Count -lt 1) {
            [pscustomobject]@{
                Server              = $computerName
                Status              = 'Healthy'
                BackPressureState   = 'None Detected'
                EventCount          = 0
                LastEventId         = $null
                LastEventTime       = $null
                HoursSinceLastEvent = $null
                LastEventMessage    = $null
            }
            continue
        }

        $lastEvent = $events | Select-Object -First 1
        $hoursAgo = [math]::Round(((Get-Date) - $lastEvent.TimeCreated).TotalHours, 2)
        $state = Get-BackPressureState -EventId $lastEvent.Id -ReplacementStrings $lastEvent.Properties.Value

        [pscustomobject]@{
            Server              = $computerName
            Status              = 'BackPressureDetected'
            BackPressureState   = $state
            EventCount          = $events.Count
            LastEventId         = $lastEvent.Id
            LastEventTime       = $lastEvent.TimeCreated
            HoursSinceLastEvent = $hoursAgo
            LastEventMessage    = if ($IncludeEventDetails) { $lastEvent.Message } else { $null }
        }
    }
    catch {
        [pscustomobject]@{
            Server              = $computerName
            Status              = 'Error'
            BackPressureState   = 'Unknown'
            EventCount          = $null
            LastEventId         = $null
            LastEventTime       = $null
            HoursSinceLastEvent = $null
            LastEventMessage    = $_.Exception.Message
        }
    }
}

$results |
    Sort-Object Server |
    Format-Table -AutoSize Server, Status, BackPressureState, EventCount, LastEventId, LastEventTime, HoursSinceLastEvent

if ($ReportPath) {
    $reportDirectory = Split-Path -Path $ReportPath -Parent
    if ($reportDirectory -and -not (Test-Path -Path $reportDirectory)) {
        New-Item -ItemType Directory -Path $reportDirectory -Force | Out-Null
    }

    $results | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8
    Write-Verbose "Report written to $ReportPath"
}
