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
    Invoke-EnterpriseTemplate.ps1

.SYNOPSIS
    Enterprise-ready reusable PowerShell script template.

.DESCRIPTION
    This template provides a GitHub-safe foundation for enterprise PowerShell automation.
    It includes:
    - Comment-based help
    - Parameter validation
    - Admin elevation support
    - Transcript logging
    - Local file logging
    - Optional remote logging stub
    - Prerequisite testing
    - Structured error handling
    - ShouldProcess support for safer execution

.PARAMETER LogRoot
    Root folder where transcript and log files will be stored.

.PARAMETER EnableTranscript
    Enables PowerShell transcript logging.

.PARAMETER EnableRemoteLogging
    Enables the optional remote logging function.

.PARAMETER RemoteLogUri
    Remote logging endpoint URI. Use a placeholder or a secure secret store in production.

.PARAMETER RemoteLogToken
    Remote logging authorization token. Do not hardcode real values in public repositories.

.PARAMETER SkipAdminCheck
    Skips the administrator privilege check.

.PARAMETER Force
    Bypasses confirmation prompts where applicable.

.EXAMPLE
    .\Invoke-EnterpriseTemplate.ps1

.EXAMPLE
    .\Invoke-EnterpriseTemplate.ps1 -EnableTranscript -Verbose

.EXAMPLE
    .\Invoke-EnterpriseTemplate.ps1 -LogRoot "C:\ProgramData\EnterpriseTemplate\Logs" -WhatIf

.EXAMPLE
    .\Invoke-EnterpriseTemplate.ps1 -EnableRemoteLogging -RemoteLogUri "https://logging.example.com/collector" -RemoteLogToken "<TOKEN>"

.NOTES
    Version:        1.0.0
    Author:         RSmith
    Creation Date:  2022-05-26
    Purpose/Change: Initial public GitHub-safe enterprise template

.LINK
    https://github.com/rsmith7712/powershell-scripts

.HISTORY
    1.0.0 - Initial template release
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$LogRoot = "C:\ProgramData\EnterpriseTemplate\Logs",

    [Parameter()]
    [switch]$EnableTranscript,

    [Parameter()]
    [switch]$EnableRemoteLogging,

    [Parameter()]
    [ValidatePattern('^https://')]
    [string]$RemoteLogUri = "https://logging.example.com/services/collector/event",

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$RemoteLogToken = "<TOKEN>",

    [Parameter()]
    [switch]$SkipAdminCheck,

    [Parameter()]
    [switch]$Force
)

begin {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    $script:ScriptName        = if ($PSCommandPath) { Split-Path -Leaf $PSCommandPath } else { 'Invoke-EnterpriseTemplate.ps1' }
    $script:ScriptBaseName    = [System.IO.Path]::GetFileNameWithoutExtension($script:ScriptName)
    $script:ScriptPath        = $PSCommandPath
    $script:RunId             = "{0}.{1}" -f (Get-Date -Format 'yyyyMMdd_HHmmss'), (Get-Random -Minimum 100000 -Maximum 999999)
    $script:SessionRoot       = Join-Path $LogRoot $script:ScriptBaseName
    $script:LogFile           = Join-Path $script:SessionRoot "$($script:ScriptBaseName)_$($script:RunId).log"
    $script:TranscriptFile    = Join-Path $script:SessionRoot "$($script:ScriptBaseName)_$($script:RunId)_Transcript.txt"
    $script:FixMeFile         = Join-Path $script:SessionRoot "$($script:ScriptBaseName)_$($script:RunId)_FixMe.log"
    $script:TranscriptStarted = $false
}

process {

    function Initialize-Logging {
        [CmdletBinding()]
        param()

        if (-not (Test-Path -Path $script:SessionRoot)) {
            New-Item -Path $script:SessionRoot -ItemType Directory -Force | Out-Null
        }

        New-Item -Path $script:LogFile -ItemType File -Force | Out-Null
        New-Item -Path $script:FixMeFile -ItemType File -Force | Out-Null
    }

    function Write-Log {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [ValidateNotNullOrEmpty()]
            [string]$Message,

            [Parameter()]
            [ValidateSet('INFO','WARN','ERROR','DEBUG','SUCCESS')]
            [string]$Level = 'INFO',

            [Parameter()]
            [string]$ForegroundColor
        )

        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $entry = "$timestamp [$Level] $Message"

        if (-not $ForegroundColor) {
            $ForegroundColor = switch ($Level) {
                'INFO'    { 'White' }
                'WARN'    { 'Yellow' }
                'ERROR'   { 'Red' }
                'DEBUG'   { 'Cyan' }
                'SUCCESS' { 'Green' }
                default   { 'White' }
            }
        }

        Write-Host $entry -ForegroundColor $ForegroundColor
        Add-Content -Path $script:LogFile -Value $entry -Encoding UTF8
    }

    function Write-FixMe {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [ValidateNotNullOrEmpty()]
            [string]$Message
        )

        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $entry = "$timestamp [ACTION] $Message"
        Add-Content -Path $script:FixMeFile -Value $entry -Encoding UTF8
    }

    function Start-ScriptTranscript {
        [CmdletBinding()]
        param()

        if ($EnableTranscript -and -not $script:TranscriptStarted) {
            Start-Transcript -Path $script:TranscriptFile -Force | Out-Null
            $script:TranscriptStarted = $true
            Write-Log -Message "Transcript started: $($script:TranscriptFile)" -Level INFO
        }
    }

    function Stop-ScriptTranscript {
        [CmdletBinding()]
        param()

        if ($script:TranscriptStarted) {
            try {
                Stop-Transcript | Out-Null
            }
            catch {
                Write-Log -Message "Unable to stop transcript cleanly: $($_.Exception.Message)" -Level WARN
            }
        }
    }

    function Test-IsAdministrator {
        [CmdletBinding()]
        param()

        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    function Restart-Elevated {
        [CmdletBinding()]
        param()

        if (-not $script:ScriptPath) {
            throw "Unable to relaunch script because PSCommandPath is not available."
        }

        $argumentList = @(
            '-NoProfile'
            '-ExecutionPolicy', 'Bypass'
            '-File', "`"$script:ScriptPath`""
        )

        foreach ($boundKey in $PSBoundParameters.Keys) {
            switch ($boundKey) {
                'EnableTranscript'    { if ($EnableTranscript)    { $argumentList += '-EnableTranscript' } }
                'EnableRemoteLogging' { if ($EnableRemoteLogging) { $argumentList += '-EnableRemoteLogging' } }
                'SkipAdminCheck'      { if ($SkipAdminCheck)      { $argumentList += '-SkipAdminCheck' } }
                'Force'               { if ($Force)               { $argumentList += '-Force' } }
                'LogRoot'             { $argumentList += @('-LogRoot', "`"$LogRoot`"") }
                'RemoteLogUri'        { $argumentList += @('-RemoteLogUri', "`"$RemoteLogUri`"") }
                'RemoteLogToken'      { $argumentList += @('-RemoteLogToken', "`"$RemoteLogToken`"") }
            }
        }

        Write-Log -Message 'Script is not running elevated. Attempting to relaunch as Administrator.' -Level WARN

        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = 'powershell.exe'
        $startInfo.Arguments = $argumentList -join ' '
        $startInfo.Verb = 'runas'
        $startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Normal

        [System.Diagnostics.Process]::Start($startInfo) | Out-Null
        exit
    }

    function Send-RemoteLog {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [ValidateNotNullOrEmpty()]
            [string]$Message,

            [Parameter()]
            [ValidateSet('Informational','Warning','Error','Success')]
            [string]$Status = 'Informational',

            [Parameter()]
            [ValidateSet('Log','Audit','Metric','Event')]
            [string]$Type = 'Log',

            [Parameter()]
            [Nullable[int]]$Id = $null
        )

        if (-not $EnableRemoteLogging) {
            return
        }

        try {
            $headers = @{
                'Content-Type'  = 'application/json'
                'Authorization' = "Bearer $RemoteLogToken"
            }

            $payload = @{
                source     = $script:ScriptName
                sourcetype = 'company:ps:log'
                host       = $env:COMPUTERNAME
                event      = @{
                    message   = $Message
                    user      = $env:USERNAME
                    product   = "teamname_$($script:ScriptBaseName)"
                    type      = $Type
                    status    = $Status
                    id        = $Id
                    runId     = $script:RunId
                    timestamp = (Get-Date).ToString('o')
                }
            } | ConvertTo-Json -Depth 5

            Invoke-RestMethod -Uri $RemoteLogUri -Method Post -Headers $headers -Body $payload -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Log -Message "Remote logging failed: $($_.Exception.Message)" -Level WARN
        }
    }

    function Test-Prerequisites {
        [CmdletBinding()]
        param()

        Write-Log -Message 'Running prerequisite validation.' -Level INFO

        $checks = [System.Collections.Generic.List[string]]::new()

        if (-not (Get-Command powershell.exe -ErrorAction SilentlyContinue)) {
            $checks.Add('powershell.exe was not found in the current environment.')
        }

        if (-not (Test-Path -Path $LogRoot)) {
            try {
                New-Item -Path $LogRoot -ItemType Directory -Force | Out-Null
            }
            catch {
                $checks.Add("Unable to create or access log root path: $LogRoot")
            }
        }

        if ($EnableRemoteLogging) {
            if ([string]::IsNullOrWhiteSpace($RemoteLogUri) -or $RemoteLogUri -eq 'https://logging.example.com/services/collector/event') {
                Write-Log -Message 'Remote logging is enabled with a placeholder URI. Replace it before production use.' -Level WARN
                Write-FixMe -Message 'Replace RemoteLogUri placeholder with a real endpoint or disable remote logging.'
            }

            if ([string]::IsNullOrWhiteSpace($RemoteLogToken) -or $RemoteLogToken -eq '<TOKEN>') {
                Write-Log -Message 'Remote logging is enabled with a placeholder token. Replace it before production use.' -Level WARN
                Write-FixMe -Message 'Replace RemoteLogToken placeholder with a secure secret or disable remote logging.'
            }
        }

        if ($checks.Count -gt 0) {
            foreach ($check in $checks) {
                Write-Log -Message $check -Level ERROR
            }
            return $false
        }

        Write-Log -Message 'Prerequisite validation completed successfully.' -Level SUCCESS
        return $true
    }

    function Invoke-Main {
        [CmdletBinding()]
        param()

        if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Execute enterprise template main logic')) {
            Write-Log -Message 'Main execution block reached. Insert task-specific logic here.' -Level INFO
            Send-RemoteLog -Message 'Main execution block reached.' -Status Informational -Type Event -Id 1000

            # ------------------------------------------------------------------------------------------
            # Insert task-specific logic here
            # ------------------------------------------------------------------------------------------
        }
    }

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        Initialize-Logging
        Start-ScriptTranscript

        Write-Log -Message "[BEGIN] Script started. RunId = $($script:RunId)" -Level INFO
        Send-RemoteLog -Message 'Script started.' -Status Informational -Type Event -Id 1

        if (-not $SkipAdminCheck -and -not (Test-IsAdministrator)) {
            Restart-Elevated
        }
        else {
            Write-Log -Message 'Administrator check passed or explicitly skipped.' -Level INFO
        }

        if (-not (Test-Prerequisites)) {
            Send-RemoteLog -Message 'Prerequisite validation failed.' -Status Error -Type Audit -Id 1001
            throw 'Prerequisite validation failed.'
        }

        Invoke-Main

        $stopwatch.Stop()
        $elapsedMinutes = [math]::Round($stopwatch.Elapsed.TotalMinutes, 2)

        Write-Log -Message "[END] Script completed successfully. TTC = $elapsedMinutes minute(s)." -Level SUCCESS
        Send-RemoteLog -Message "Script completed successfully in $elapsedMinutes minute(s)." -Status Success -Type Event -Id 2
        exit 0
    }
    catch {
        $stopwatch.Stop()
        $elapsedMinutes = [math]::Round($stopwatch.Elapsed.TotalMinutes, 2)
        $errorMessage = $_.Exception.Message

        Write-Log -Message "Script failed after $elapsedMinutes minute(s): $errorMessage" -Level ERROR
        Write-FixMe -Message $errorMessage
        Send-RemoteLog -Message "Script failed: $errorMessage" -Status Error -Type Event -Id 5000

        exit 1
    }
    finally {
        Stop-ScriptTranscript
    }
}
