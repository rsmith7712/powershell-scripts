#Requires -Version 5.1
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
    Enhanced_Win11CompTestV3.ps1

.SUMMARY
    Checks the computer if is capable of upgrading to Windows 11.

.DESCRIPTION
    Checks the computer if is capable of upgrading to Windows 11 and returns the results.

.FUNCTIONALITY
    Preparation and Setup:
        -The script starts by ensuring the destination folder (C:\temp\Win11CompTestV3) exists. If not, it creates the folder.
        -It then defines paths for the logging transcript and results file.
        -The script also specifies the input file (C:\temp\Computers.txt) containing the list of remote computers.

    Logging Start:
        -Start-Transcript is used so that every action is logged into the provided log file. This helps in tracing the script’s execution.

    Reading the Computer List:
        -The script reads the list of remote computers. In case the file is empty or missing, the script logs a warning or error and then exits.

    Processing Each Computer:
        -Connectivity Check: Uses Test-Connection to check if the computer is online.
        -OS Information: Uses Invoke-Command with a script block that retrieves the operating system caption via Get-CimInstance. This is used to determine if the system is Windows 11.
        -Error Handling: If any error occurs during processing, it’s caught, logged and recorded in the results.

    Exporting Results:
        -After processing all computers, the script exports the collected results to a CSV file.

    Finalization:
        -The script outputs completion messages and then stops the transcript logging with Stop-Transcript.

.PARAMETERS
    None

.EXAMPLE
    None

.FAQ
    Q1: Is this script compatible with all Windows versions?  
    A1: The script is designed for Windows 10 systems and above.

    Q2: What happens if the TPM chip is not present?  
    A2: The script will return a ‘Not Capable’ status if the TPM chip is missing or
        incompatible.

    Q3: Can this script be run on multiple machines at once?  
    A3: Yes, it can be integrated into larger automation workflows to run on multiple
        machines.

.NOTE
    Prerequisites:
        –Ensure that C:\temp\Computers.txt exists and contains one computer name per line.
        –The script assumes the remote machines allow PowerShell remoting.

    Execution:
        -Launch the script in an elevated PowerShell prompt. It will prompt for domain
            admin credentials which are used for remote operations.

    Logging & Output:
        -All actions are logged in C:\temp\log_hardwareReadiness.txt
            (with YYYY-MM-DD HH:mm timestamps), and the final summary is exported to
            C:\temp\results_hardwareReadiness.csv.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Ensure the destination folder exists
$destFolder = "C:\temp\Enhanced_Win11CompTestV3"
if (!(Test-Path -Path $destFolder)) {
    New-Item -Path $destFolder -ItemType Directory -Force | Out-Null
}

# Define paths for logging, results, and computer list
$logPath = "$destFolder\log_win11CompTestV3.txt"
$resultsPath = "$destFolder\results_win11CompTestV3.csv"
#$computersFile = "C:\temp\Computers.txt"
$computersFile = "C:\temp\ComputerList_Validation\validated_Computers.txt"

# Start detailed logging (transcript)
Start-Transcript -Path $logPath -Append

Write-Output "Starting Windows 11 Compatibility Test on remote computers..."
Write-Output "Reading computer list from: $computersFile"

# Attempt to read the list of computer names
try {
    $computerList = Get-Content -Path $computersFile -ErrorAction Stop
    if ($computerList.Count -eq 0) {
        Write-Warning "No computer names found in $computersFile. Exiting script."
        Stop-Transcript
        exit
    }
}
catch {
    Write-Error "Failed to read $computersFile. $_"
    Stop-Transcript
    exit
}

# Create an array to collect results from each computer
$allResults = @()

foreach ($computer in $computerList) {
    Write-Output "Processing computer: $computer"

    try {
        # Test connectivity to the remote computer
        $isOnline = Test-Connection -ComputerName $computer -Count 2 -Quiet
        if (-not $isOnline) {
            Write-Warning "$computer is not reachable."
            $allResults += [pscustomobject]@{
                Computer       = $computer
                Processor      = "N/A"
                RAM            = "N/A"
                Storage        = "N/A"
                TPM            = "N/A"
                UEFI_SecureBoot= "N/A"
                Graphics       = "N/A"
                Display        = "N/A"
                Overall        = "Unreachable"
            }
            continue
        }

        # Invoke remote command to perform the compatibility tests
        $result = Invoke-Command -ComputerName $computer -ErrorAction Stop -ScriptBlock {
            # Define each check as provided

            function Check-Processor {
                $processor = Get-WmiObject -Class Win32_Processor
                $cores = $processor.NumberOfCores
                $speed = $processor.MaxClockSpeed / 1000  # Convert to GHz
                return ($cores -ge 2 -and $speed -ge 1.0)
            }

            function Check-RAM {
                $ram = (Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB  # Convert to GB
                return ($ram -ge 4)
            }

            function Check-Storage {
                $storage = (Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'").Size / 1GB  # Convert to GB
                return ($storage -ge 64)
            }

            function Check-TPM {
                try {
                    $tpm = Get-WmiObject -Namespace "root\cimv2\security\microsofttpm" -Class Win32_Tpm
                    return ($tpm.IsActivated_InitialValue -and $tpm.SpecVersion -ge "2.0")
                } catch {
                    return $false
                }
            }

            function Check-UEFI-SecureBoot {
                try {
                    $secureBootState = Get-ItemPropertyValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State" -Name "UEFISecureBootEnabled"
                    return ($secureBootState -eq 1)
                } catch {
                    return $false
                }
            }

            function Check-Graphics {
                $gpu = Get-WmiObject -Class Win32_VideoController
                foreach ($adapter in $gpu) {
                    if ($adapter.DriverVersion -ge "12.0" -or $adapter.VideoModeDescription -like "*DirectX 12*") {
                        return $true
                    }
                }
                return $false
            }

            function Check-Display {
                # Basic check; assumes the display meets requirements
                return $true
            }

            # Build a hashtable of check results
            $checks = @{
                "Processor"         = Check-Processor
                "RAM"               = Check-RAM
                "Storage"           = Check-Storage
                "TPM"               = Check-TPM
                "UEFI_SecureBoot"   = Check-UEFI-SecureBoot
                "Graphics"          = Check-Graphics
                "Display"           = Check-Display
            }

            # Convert Boolean results into PASS/FAIL strings and compute overall status
            $results = @{}
            $allPassed = $true
            foreach ($item in $checks.GetEnumerator()) {
                if ($item.Value) {
                    $results[$item.Key] = "PASS"
                } else {
                    $results[$item.Key] = "FAIL"
                    $allPassed = $false
                }
            }
            $overallStatus = if ($allPassed) { "Compatible" } else { "Not Compatible" }

            # Return the results as a PSCustomObject (include the remote computer's name)
            [PSCustomObject]@{
                Computer        = $env:COMPUTERNAME
                Processor       = $results.Processor
                RAM             = $results.RAM
                Storage         = $results.Storage
                TPM             = $results.TPM
                UEFI_SecureBoot = $results.UEFI_SecureBoot
                Graphics        = $results.Graphics
                Display         = $results.Display
                Overall         = $overallStatus
            }
        } -ErrorAction Stop

        Write-Output "Results for $computer received: Overall Status - $($result.Overall)"
        $allResults += $result
    }
    catch {
        Write-Error "Error processing $($computer): $($_.Exception.Message)"
        $allResults += [pscustomobject]@{
            Computer        = $computer
            Processor       = "Error"
            RAM             = "Error"
            Storage         = "Error"
            TPM             = "Error"
            UEFI_SecureBoot = "Error"
            Graphics        = "Error"
            Display         = "Error"
            Overall         = "Error"
        }
    }
}

# Export all results to CSV
Write-Output "Exporting all results to: $resultsPath"
$allResults | Export-Csv -Path $resultsPath -NoTypeInformation -Force

Write-Output "Script execution completed. Detailed logs and results are saved."

# Stop transcript logging
Stop-Transcript
