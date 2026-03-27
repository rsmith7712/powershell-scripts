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
    Execute_File_Locally_with_OS_Check.ps1

.DESCRIPTION
    Execute a file locally on each computer in a list, but only if the computer
    is running a client OS (not a server OS).

.FUNCTIONALITY
    This script is designed to execute a file locally on each computer in a
    list, but only if the computer is running a client OS (not a server OS).
    The script will read a list of computer names from a text file, check if
    each computer is reachable, determine the operating system, and then execute
    the specified file on each reachable computer that is running a client OS
    while saving the results to a specified location.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

#>

# Prompt for Domain Admin credentials at the start of the script
$domainAdminCred = Get-Credential -Message "Please enter Domain Admin credentials"

# Set up the log file path
$logFile = "C:\temp\ExecutionLog.txt"

# Function to write log entries
function Write-Log {
    param(
        [string]$message
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logMessage = "$timestamp - $message"
    Add-Content -Path $logFile -Value $logMessage
}

# Start logging
Write-Log "Starting the execution of the file on multiple computers."

$computers = Get-Content -Path "C:\temp\computers.txt"
$totalComputers = $computers.Count
$resultsFolder = "C:\temp\Win11Results"
$counter = 0

# Add a timeout value for remote operations
$remoteTimeout = 60  # Timeout in seconds for remote commands
$execTimeout = 300   # Timeout in seconds for the executable to run

foreach ($computer in $computers) {
    $counter++

    # Display progress in the console
    $percentComplete = ($counter / $totalComputers) * 100
    Write-Progress -PercentComplete $percentComplete -Status "Processing $computer" -Activity "Executing file"

    # Test connectivity to the remote machine with timeout using -Count and -Delay
    try {
        $pingResult = Test-Connection -ComputerName $computer -Quiet -Count 1 -Delay 5
        if ($pingResult) {
            Write-Log "$computer is reachable, checking OS."
        } else {
            Write-Log "$computer is not reachable, skipping."
            continue  # Skip to the next computer if unreachable
        }
    } catch {
        Write-Log "$computer is not reachable due to an error, skipping."
        continue  # Skip to the next computer if an error occurs
    }

    # Create a CIM session using provided credentials
    try {
        $session = New-CimSession -ComputerName $computer -Credential $domainAdminCred
        Write-Log "CIM session established with $computer."

        # Get the operating system of the remote computer using Get-CimInstance and the session
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $session
        Write-Log "Retrieved OS info for ${computer}: $($os.Caption)"

        # Check if the OS is a server OS
        if ($os.Caption -match "Server") {
            Write-Log "$computer is a server OS, skipping."
            continue  # Skip to the next computer if it's a server
        }

        $resultsFile = "\\$computer\C$\temp\Win11_Results_$computer.csv"

        # Define the script block and pass the $resultsFile variable explicitly
        $scriptBlock = {
            param($resultsFile)
            
            # Ensure the directory exists
            $resultsFolder = "C:\temp"
            if (-not (Test-Path $resultsFolder)) {
                New-Item -Path $resultsFolder -ItemType Directory
                Write-Log "Created $resultsFolder."
            }

            # Run the executable and output to the results file with timeout
            $process = Start-Process "C:\temp\WhyNotWin11.exe" -PassThru
            $process | Wait-Process -Timeout $execTimeout

            if ($process.HasExited) {
                Write-Log "WhyNotWin11.exe finished on $computer."
            } else {
                Write-Log "WhyNotWin11.exe timed out on $computer."
                $process.Kill()
            }
        }

        try {
            Write-Log "Executing file on $computer and saving results to $resultsFile."

            # Invoke the command with Domain Admin credentials, passing $resultsFile as a parameter
            Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock -ArgumentList $resultsFile -Credential $domainAdminCred -TimeoutSeconds $remoteTimeout
            Write-Log "Executed on $computer and saved results to $resultsFile."
        } catch {
            # Capture the exception message and log it
            $errorMessage = $_.Exception.Message
            Write-Log "Failed to execute file on ${computer}: $errorMessage"
        }

        # Clean up CIM session
        Remove-CimSession -CimSession $session
        Write-Log "CIM session removed for $computer."
    } catch {
        $errorMessage = $_.Exception.Message
        Write-Log "Error establishing CIM session for ${computer}: $errorMessage"
    }
}

Write-Log "Execution completed."
Write-Progress -PercentComplete 100 -Status "Processing Complete" -Activity "All computers processed"
