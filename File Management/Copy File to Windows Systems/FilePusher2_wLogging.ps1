# LEGAL
<# LICENSE
    MIT License, Copyright 2024 Richard Smith

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
    FilePusher2_wLogging.ps1

.DESCRIPTION
    Copy a file to multiple Windows systems with logging

.FUNCTIONALITY
    This script is designed to copy a file to multiple Windows systems.  The
    script will query Active Directory for all Windows-based computer accounts,
    and attempt to copy a specified file to a specified folder on each system
    using PowerShell remoting.  The script will prompt for Domain Admin credentials
    to use for the remoting sessions.  The script will also log the results of
    each copy attempt, including successes, failures, and unreachable systems,
    to a CSV file.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

#>

# Import the Active Directory cmdlets
Import-Module ActiveDirectory -ErrorAction Stop

# Prompt for your Domain Admin credentials
$cred = Get-Credential -Message 'Enter Domain Admin credentials'

# Get all Windows–based computer names from AD
$computers = Get-ADComputer -Filter {OperatingSystem -like "*Windows*"} |
             Select-Object -ExpandProperty Name

# Local source file and remote path
$sourceFile = "C:\temp\Win11CompTestV3.ps1"
$remotePath = "C:\temp"

# Prepare an array to hold log entries
$results = @()

foreach ($computer in $computers) {
    $timestamp = Get-Date -Format o

    Write-Host "Applying ExecutionPolicy change on $computer…" -ForegroundColor Cyan
    try {
        Invoke-Command -ComputerName $computer -Credential $cred -ScriptBlock {
            Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
        } -ErrorAction Stop

        Write-Host "✅ Success on $computer" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed on ${computer}: $_" -ForegroundColor Red
    }

    if (Test-Connection -ComputerName $computer -Count 1 -Quiet) {
        try {
            # Establish a remoting session using the provided credentials
            $session = New-PSSession -ComputerName $computer -Credential $cred -ErrorAction Stop

            # Ensure the remote folder exists
            Invoke-Command -Session $session -ScriptBlock {
                param($path)
                if (-not (Test-Path $path)) {
                    New-Item -Path $path -ItemType Directory -Force | Out-Null
                }
            } -ArgumentList $remotePath

            # Copy the file into that folder over the session
            Copy-Item -Path $sourceFile `
                      -Destination $remotePath `
                      -ToSession $session `
                      -Force -ErrorAction Stop

            # Log success
            $results += [PSCustomObject]@{
                Computer  = $computer
                Status    = 'Success'
                Message   = "File copied"
                Timestamp = $timestamp
            }
            Write-Host "✅ [$timestamp] File copied successfully to $computer"
        }
        catch {
            # Log failure
            $results += [PSCustomObject]@{
                Computer  = $computer
                Status    = 'Failed'
                Message   = $_.Exception.Message
                Timestamp = $timestamp
            }
            Write-Warning "❌ [$timestamp] Failed to copy file to ${computer}: $($_.Exception.Message)"
        }
        finally {
            # Clean up the session if it was created
            if ($session) { Remove-PSSession $session }
        }
    }
    else {
        # Log unreachable
        $results += [PSCustomObject]@{
            Computer  = $computer
            Status    = 'Unreachable'
            Message   = 'Ping test failed'
            Timestamp = $timestamp
        }
        Write-Warning "⚠️  [$timestamp] Computer $computer is not reachable"
    }
}

# Export the collected results to CSV
$logPath = "C:\temp\FilePusher_log.csv"
$results | Export-Csv -Path $logPath -NoTypeInformation

Write-Host "Log exported to $logPath"
