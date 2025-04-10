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
    Enhanced-Win11Compatibility.ps1

.SYNOPSIS
    Enhanced Windows 11 Compatibility Check Script

.DESCRIPTION
    This script performs a Windows 11 compatibility check on remote computers.
    It reads a list of computers from a text file, verifies that the remote
    computer is online, checks and enables WinRM (if necessary), then runs a
    compatibility check against minimum requirements. The script logs detailed
    progress (with timestamps in YYYY-MM-DD HH:mm format) to
    C:\temp\log_win11compatibility.txt and exports the compatibility results
    to a CSV file.

.FUNCTIONALITY
    Configuration and Logging:
        -The script specifies the CSV file for results, a text file for the
            list of computer names, and minimum Windows 11 Pro requirements.
        -A logging function (Write-Log) creates a log file at
            C:\temp\log_win11compatibility.txt with each entry timestamped in
            YYYY-MM-DD HH:mm format.

    Domain Admin Credential Prompt:
        -The script requests credentials at the start using Get-Credential.
            All remote tasks (e.g. enabling WinRM and querying systems) use
            these credentials.

    Remote Computer Processing:
        -For each computer from the list, the script checks network
            connectivity with Test-Connection.
        -It tests for WinRM availability using Test-NetConnection and, if
            needed, enables remoting on the remote system.
        -The script then runs the Windows 11 compatibility check via an
            Invoke-Command remote session. The compatibility checks compare
            remote system properties against the specified minimum requirements.
            (Note that variables from the local session are passed in using
            $using:.)

    Error Handling and CSV Export:
        -Any error during processing is caught and logged, with a default result
            generated.
        -After processing all computers, the collected results are exported to
            the specified CSV file.

.PARAMETERS
    None
        -All required inputs (computers list, CSV output path, minimum requirements)
            are specified within the script.

.EXAMPLE
    .\Enhanced-Win11Compatibility.ps1

.FAQ

.NOTES

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

### CONFIGURATION ###

# Ensure the working directory exists
$tempDir = "C:\Temp\Enhanced_Win11_Hardware_Readiness"
if (-not (Test-Path $tempDir)) {
    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
}

# Define log and CSV file paths.
$logFile    = "$tempDir\log_win11compatibility.txt"
$resultsCSV = "$tempDir\results_win11Compatibility.csv"

# Specify the list of computers to check (e.g., from a text file)
$computers = Get-Content "C:\Temp\Computers.txt"  # Replace with your file path

# Define the minimum requirements for Windows 11 Pro
$minCPUArchitecture = "x64"
$minMemory = 4  # in GB
$minStorage = 64 # in GB
$minGraphics = "Intel HD Graphics 4000"  # Example requirement – adjust as needed

### FUNCTIONS ###

# Write-Log: Logs messages with date/time stamps (YYYY-MM-DD HH:mm) to log file and writes to host.
function Write-Log {
    param (
        [string]$Message
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm")
    $entry = "$timestamp - $Message"
    Add-Content -Path $logFile -Value $entry
    Write-Host $entry
}

### OBTAIN CREDENTIALS ###

# Request Domain Admin credentials at the start of execution
$cred = Get-Credential -Message "Enter your Domain Admin credentials"
Write-Log "Script started. Domain Admin credentials have been obtained."

### INITIALIZE RESULTS ###
$results = @()

### PROCESS EACH COMPUTER ###
foreach ($computer in $computers) {
    Write-Log "Processing computer: ${computer}"
    
    # Test if the computer is online (ping test with 2 attempts)
    if (-not (Test-Connection -ComputerName $computer -Count 2 -Quiet)) {
        Write-Log "Computer ${computer} is unreachable. Skipping to next computer."
        $results += [PSCustomObject]@{
            ComputerName    = $computer
            CPUArchitecture = "N/A"
            CPUName         = "N/A"
            TotalMemory     = "N/A"
            Storage         = "N/A"
            GraphicsAdapter = "N/A"
            IsCompatible    = $false
        }
        continue
    }
    Write-Log "Computer ${computer} is online."
    
    # Check if WinRM (port 5985) is enabled on the remote computer.
    try {
        $winrmTest = Test-NetConnection -ComputerName $computer -Port 5985 -WarningAction SilentlyContinue
    }
    catch {
        Write-Log "Error testing WinRM connectivity on ${computer}: $($_.Exception.Message)"
        continue
    }

    if ($winrmTest.TcpTestSucceeded) {
        Write-Log "WinRM is already enabled on ${computer}."
    }
    else {
        Write-Log "WinRM is not enabled on ${computer}. Attempting to enable WinRM remotely."
        try {
            Invoke-Command -ComputerName $computer -Credential $cred -ScriptBlock {
                # Enable PowerShell remoting and configure WinRM.
                Enable-PSRemoting -Force -SkipNetworkProfileCheck
            } -ErrorAction Stop
            Write-Log "Successfully enabled WinRM on ${computer}."
        }
        catch {
            Write-Log "Failed to enable WinRM on ${computer}. Error: $($_.Exception.Message)"
            $results += [PSCustomObject]@{
                ComputerName    = $computer
                CPUArchitecture = "N/A"
                CPUName         = "N/A"
                TotalMemory     = "N/A"
                Storage         = "N/A"
                GraphicsAdapter = "N/A"
                IsCompatible    = $false
            }
            continue
        }
    }
    
    ### REMOTE WINDOWS 11 COMPATIBILITY CHECK ###
    try {
        Write-Log "Starting Windows 11 compatibility check on ${computer}."
        $compResult = Invoke-Command -ComputerName $computer -Credential $cred -ScriptBlock {
            # Retrieve system data
            $cpuArchitecture = (Get-CimInstance -ClassName Win32_ComputerSystem).Architecture
            $cpuName = (Get-CimInstance -ClassName Win32_Processor).Name
            $totalMemory = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalMemory
            $memoryInGB = [math]::Round($totalMemory / 1GB, 2)
            $storageDevices = Get-CimInstance -ClassName Win32_DiskDrive
            # For simplicity, use the capacity of the first disk drive (adjust if you need to handle multiple devices)
            $storageCapacity = if($storageDevices.Count -gt 0) { ([int]($storageDevices[0].Capacity / 1GB)) } else { 0 }
            $graphicsAdapter = (Get-CimInstance -ClassName Win32_VideoController).Name

            # Use the minimum requirement values from the parent session ($using:) for remote comparisons
            $minCPUArchitecture = $using:minCPUArchitecture
            $minMemory = $using:minMemory
            $minStorage = $using:minStorage
            $minGraphics = $using:minGraphics

            # Check if the computer meets the minimum requirements
            $isCompatible = $true
            if ($cpuArchitecture -ne $minCPUArchitecture) {
                Write-Warning "CPU Architecture: $cpuArchitecture is not compatible with Windows 11 Pro"
                $isCompatible = $false
            }
            if ($memoryInGB -lt $minMemory) {
                Write-Warning "Total Memory: $memoryInGB GB is less than the minimum requirement of $minMemory GB"
                $isCompatible = $false
            }
            if ($storageCapacity -lt $minStorage) {
                Write-Warning "Storage: $storageCapacity GB is less than the minimum requirement of $minStorage GB"
                $isCompatible = $false
            }
            if ($graphicsAdapter -notlike "*$minGraphics*") {
                Write-Warning "Graphics Card: $graphicsAdapter is not compatible with Windows 11 Pro"
                $isCompatible = $false
            }

            # Create and return a custom object with the system details and compatibility result
            [PSCustomObject]@{
                ComputerName    = $env:COMPUTERNAME
                CPUArchitecture = $cpuArchitecture
                CPUName         = $cpuName
                TotalMemory     = $memoryInGB
                Storage         = "$storageCapacity GB"
                GraphicsAdapter = $graphicsAdapter
                IsCompatible    = $isCompatible
            }
        } -ErrorAction Stop

        # Append the result from this computer to the results array and log output
        $results += $compResult
        Write-Log "Compatibility check for ${computer}: CPU: $($compResult.CPUArchitecture), Memory: $($compResult.TotalMemory)GB, Storage: $($compResult.Storage), Graphics: $($compResult.GraphicsAdapter), Compatible: $($compResult.IsCompatible)"
    }
    catch {
        Write-Log "Error during compatibility check on ${computer}: $($_.Exception.Message)"
        $results += [PSCustomObject]@{
            ComputerName    = $computer
            CPUArchitecture = "N/A"
            CPUName         = "N/A"
            TotalMemory     = "N/A"
            Storage         = "N/A"
            GraphicsAdapter = "N/A"
            IsCompatible    = $false
        }
    }
    Write-Log "Finished processing computer: ${computer}"
}

### EXPORT RESULTS ###
try {
    $results | Export-Csv -Path $resultsCSV -NoTypeInformation -Force
    Write-Log "Results exported to $resultsCSV"
    Write-Host "Results exported to $resultsCSV"
}
catch {
    Write-Log "Error exporting results to CSV: $($_.Exception.Message)"
    Write-Host "Error exporting results to CSV: $($_.Exception.Message)"
}

Write-Log "Script completed."
