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
    ComputerList_Validation.ps1

.SUMMARY
    PowerShell script that reads computer names from a text file, checks if each
    computer exists in Active Directory using the ActiveDirectory module, verifies
    DNS registration via the Resolve-DnsName cmdlet, logs all actions, and finally
    exports a summary CSV report. You can save the script as, for example,
    ComputerList_Validation.ps1 and run it with the necessary privileges.

.DESCRIPTION
    PowerShell script to validate a list of remote computers against Active Directory
    and DNS then outputs results to CSV

.FUNCTIONALITY
    File Paths and Directories:
        -It sets variables for the input computer list, output CSV file, and log file.
        -It creates the output directory if it does not exist.

    Logging Function:
        -The Write-Log function writes messages to both the console and the log file along with a timestamp.

    Module and File Checks:
        -The script checks for the existence of the computer list file.
        -It verifies that the ActiveDirectory module is available and imports it.

    Processing Each Computer:
        -For each computer name read from the file, it logs the action, and initializes a custom object to capture the computer's status.

        Active Directory Validation:
            -Uses Get-ADComputer to check if the computer exists in AD.
            -Records the distinguished name if found; if not, it logs and records the error.

        DNS Validation:
            -Uses Resolve-DnsName to try resolving the computer name in DNS.
            -Sets a flag in the output based on whether the resolution was successful or not.

    Output and Logging:
        -The results are exported as a CSV to the specified path.
        -All significant actions and errors are logged to the log file.

.PARAMETERS
    None

.EXAMPLE
    None

.FAQ
    None

.NOTE
    Prerequisites:
        –Ensure that C:\temp\Computers.txt exists and contains one computer name per line.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Define file paths
$computersListPath = "C:\temp\Computers.txt"
$outputCSVPath = "C:\temp\ComputerList_Validation\results_computerListValidation.csv"
$validatedComputersPath = "C:\temp\ComputerList_Validation\validated_Computers.txt"
$logFilePath   = "C:\temp\ComputerList_Validation\log_computerListValidation.txt"

# Ensure output directory exists
$outputDir = Split-Path $outputCSVPath
if (-not (Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force
}

# Start logging function
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$Level] $Message"
    Write-Output $logMessage
    Add-Content -Path $logFilePath -Value $logMessage
}

Write-Log "Starting computer list validation."

# Verify that the input file exists
if (-not (Test-Path $computersListPath)) {
    Write-Log "The computer list file '$computersListPath' was not found." "ERROR"
    exit 1
}

# Import the Active Directory module if not already loaded
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Log "ActiveDirectory module not found. Ensure the RSAT tools are installed." "ERROR"
    exit 1
} else {
    Import-Module ActiveDirectory
    Write-Log "ActiveDirectory module loaded successfully."
}

# Read computer names
$computers = Get-Content -Path $computersListPath
if ($computers.Count -eq 0) {
    Write-Log "The computer list is empty." "WARN"
    exit 1
}

# Create collections to hold validation results and validated computers.
$results = @()
$validatedComputers = @()

# Validate each computer
foreach ($computer in $computers) {
    $computer = $computer.Trim()
    if ([string]::IsNullOrWhiteSpace($computer)) { continue }

    Write-Log "Processing computer: $computer"

    # Initialize result object
    $resultObject = [PSCustomObject]@{
        ComputerName        = $computer
        InActiveDirectory   = $false
        InDNS               = $false
        ADInfo              = $null
        DNSErrors           = $null
    }

    # Check Active Directory
    try {
        $adComputer = Get-ADComputer -Identity $computer -ErrorAction Stop
        if ($adComputer) {
            $resultObject.InActiveDirectory = $true
            $resultObject.ADInfo = $adComputer.DistinguishedName
            Write-Log "AD entry found for $computer. DN: $($resultObject.ADInfo)"
        }
    } catch {
        Write-Log "No Active Directory entry found for $computer." "WARN"
        $resultObject.ADInfo = $_.Exception.Message
    }

    # Check DNS
    try {
        # Attempt DNS resolution with error capture.
        $dnsResult = Resolve-DnsName -Name $computer -ErrorAction Stop
        if ($dnsResult) {
            $resultObject.InDNS = $true
            Write-Log "DNS entry found for $computer."
        }
    } catch {
        Write-Log "No DNS entry found for $computer." "WARN"
        $resultObject.DNSErrors = $_.Exception.Message
    }

    # Add the result object to the results collection
    $results += $resultObject

    # If both validations passed, add to the validated list.
    if ($resultObject.InActiveDirectory -and $resultObject.InDNS) {
        $validatedComputers += $computer
    }
}

# Export the results to CSV
try {
    $results | Export-Csv -Path $outputCSVPath -NoTypeInformation -Force
    Write-Log "Results exported successfully to $outputCSVPath."
} catch {
    Write-Log "Error exporting results to CSV: $($_.Exception.Message)" "ERROR"
}

# Write validated computer names to text file
try {
    $validatedComputers | Out-File -FilePath $validatedComputersPath -Force
    Write-Log "Validated computers exported successfully to $validatedComputersPath."
} catch {
    Write-Log "Error exporting validated computers: $($_.Exception.Message)" "ERROR"
}

Write-Log "Computer list validation completed."
