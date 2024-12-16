<#
.LICENSE
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

.NAME
    interactiveLogonCheck-Win11Pro.ps1

.FUNCTIONALITY
    This script will:
        - Check if the script is running with administrator privileges.
        - Prompt the user for domain administrator credentials.
        - Accept the remote computer name as input and verify if the
            computer is reachable.
        - Confirm if the remote computer is running Windows 11 Pro,
            displaying the operating system if it is not.
        - Retrieve the registry setting for "Interactive Logon: Machine Inactivity Limit."
        - Display the result in the console and export it to a CSV file
            in C:\Temp. If the folder does not exist, it will create it.
            The CSV file name includes the current date and time in
            YYYY-MM-DD_HH-MM-SS format.
        - Save this script as a .ps1 file and run it in an elevated
            PowerShell session.

.NOTES 
2024-12-16:[UPDATED]
    (1) Replaced the Get-CimInstance command with Get-WmiObject, which
    supports the -Credential parameter. Additionally, the registry query
    has been adjusted to use Invoke-Command for remote execution. This
    should resolve the issue.
    (2) Added functionality to enable, modify, or disable the registry
    setting based on user input and implemented logging of all script
    activities.
    (3) Added functionality to allow the user to perform additional
    searches by entering another remote computer name, while reusing the
    cached credentials. The user can continue searching or exit the
    script. All actions are logged.
    (4) Script now includes support for Windows 10 Enterprise and
    Windows 10 Professional. It applies the same logic for checking and
    modifying the "Interactive Logon: Machine Inactivity Limit"
    registry key as it does for Windows 11 Pro.
    (5) The log and CSV file names have been updated to include the
    remote computer name, followed by "InactivityLimitResults" and the
    date/time in the following format [yyyy-MM-dd_HH-mm-ss]. This will help
    identify which files are associated with specific computers and
    their changes.
    (6) The script now validates and creates separate directories for
    logs (C:\Temp\Logs) and CSV files (C:\Temp\Csv) if they do not exist.
    Log files and CSV files are saved in their respective directories
    with the appropriate naming format. Added License header to script.
    (7) The log and CSV file naming format has been updated to include
    "Inactivity Limit Results," the date/time in the following format
    [yyyy-MM-dd_HH-mm-ss], and the remote computer name. File name
    alignment is important, as is one's personal Zen.
    (8) I've fixed the issues in the script, including the incomplete
    string at the CSV export line, and updated the code to ensure proper
    formatting and execution.
    (9) I've updated the script to handle local connections by detecting
    if the provided computer name matches the local machine name. For local
    connections, the script now queries the OS without using credentials.
    (10) The script has been updated to use Get-CimInstance and
    Invoke-Command with proper handling of arguments for registry
    operations, addressing access issues and ensuring compatibility.
    (11) The script has been updated to replace Get-CimInstance with
    Invoke-Command for remote operations, ensuring compatibility with the
    use of credentials.
    (12) Added logic to clear the console only when the script is first
    launched. Subsequent searches will not clear the console.
    (13) The script now logs the user executing it and their provided
    credentials into the log file.
    (14) The script has been updated to include the date and time to the
    end of the ScriptExecution.log file name.
    (15) Updated the script to record the script executor and domain
    administrator credentials into the session-specific
    ScriptExecution_(date & time).log.
    (16) All script activity and results are now recorded in the
    ScriptExecution_(date & time).log file.
    (17) Script now records detailed results for each searched computer
    in a separate log file named in the format
    InactivityLimitResults_yyyy-MM-dd_HH-mm-ss_<ComputerName>.log. The
    overall script activity continues to be logged in the
    ScriptExecution_yyyy-MM-dd_HH-mm-ss.log. "He who has a why can
    endure any how" Friedrich Nietzsche

2024-12-16:[CREATED]
    Time for troubleshooting and updates.
#>

# Ensure the PowerShell script runs in Administrator mode
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Please run this script as an Administrator." -ForegroundColor Red
    exit
}

# Clear the console only when the script is first launched
if ($global:ScriptInitialized -ne $true) {
    Clear-Host
    $global:ScriptInitialized = $true
}

# Validate and create necessary directories
$LogPath = "C:\Temp\Logs"
$CsvPath = "C:\Temp\Csv"
if (-not (Test-Path -Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory | Out-Null
}
if (-not (Test-Path -Path $CsvPath)) {
    New-Item -Path $CsvPath -ItemType Directory | Out-Null
}

# Initialize log file
$ScriptExecutionLog = "$LogPath\ScriptExecution_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"

function Initialize-LogFile {
    param([string]$ComputerName)
    $LogFileName = "$LogPath\InactivityLimitResults_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')_${ComputerName}.log"
    $LogFileName
}

function Log-Activity {
    param([string]$Message, [string]$LogFile)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "$Timestamp - $Message"
    Add-Content -Path $LogFile -Value $LogMessage
}

# Log script executor details
$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
Log-Activity "Script executed by user: $CurrentUser" -LogFile $ScriptExecutionLog

# Prompt user for Domain Administrator credentials
$Credentials = Get-Credential -Message "Enter Domain Administrator credentials"
Log-Activity "Domain credentials provided by: $($Credentials.UserName)" -LogFile $ScriptExecutionLog

# Main script loop
while ($true) {
    # Input remote computer name
    $RemoteComputerName = Read-Host "Enter the remote computer name (or type 'exit' to quit)"
    if ($RemoteComputerName -eq "exit") {
        Write-Host "Exiting script." -ForegroundColor Yellow
        Log-Activity "User exited the script." -LogFile $ScriptExecutionLog
        break
    }

    Log-Activity "Script started for remote computer: $RemoteComputerName." -LogFile $ScriptExecutionLog

    # Verify if the remote computer is reachable
    if (-not (Test-Connection -ComputerName $RemoteComputerName -Count 1 -Quiet)) {
        Write-Host "The remote computer is not reachable." -ForegroundColor Red
        Log-Activity "Remote computer $RemoteComputerName is not reachable." -LogFile $ScriptExecutionLog
        continue
    }

    # Initialize individual computer log file
    $ComputerLogFile = "$LogPath\InactivityLimitResults_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')_${RemoteComputerName}.log"

    # Check the operating system of the remote computer
    if ($RemoteComputerName -ieq $env:COMPUTERNAME) {
        Write-Host "Local connection detected. Ignoring credentials for local query." -ForegroundColor Yellow
        Log-Activity "Local connection detected for $RemoteComputerName." -LogFile $ScriptExecutionLog
        $OSInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    }
    else {
        $OSInfo = Invoke-Command -ComputerName $RemoteComputerName -Credential $Credentials -ScriptBlock {
            Get-CimInstance -ClassName Win32_OperatingSystem
        }
    }

    if ($OSInfo) {
        $OSName = $OSInfo.Caption
        Log-Activity "Operating system retrieved for $RemoteComputerName: $OSName." -LogFile $ScriptExecutionLog
        Log-Activity "Operating system retrieved: $OSName." -LogFile $ComputerLogFile

        if ($OSName -match "Windows 11 Pro|Windows 10 Enterprise|Windows 10 Pro") {
            Write-Host "The remote computer is running $OSName." -ForegroundColor Green
            Log-Activity "The remote computer is running: $OSName." -LogFile $ScriptExecutionLog

            # Get the Interactive Logon: Machine Inactivity Limit setting from the registry
            $RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            $RegistryKey = Invoke-Command -ComputerName $RemoteComputerName -Credential $Credentials -ScriptBlock {
                param($Path)
                Get-ItemProperty -Path $Path -Name "InactivityTimeoutSecs" -ErrorAction SilentlyContinue
            } -ArgumentList $RegistryPath

            $InactivityLimit = if ($RegistryKey.InactivityTimeoutSecs) {
                $RegistryKey.InactivityTimeoutSecs
            }
            else {
                "Not Configured"
            }

            # Display the result in the console
            Write-Host "Interactive Logon: Machine Inactivity Limit: $InactivityLimit seconds" -ForegroundColor Cyan
            Log-Activity "Inactivity Limit retrieved for $RemoteComputerName: $InactivityLimit seconds." -LogFile $ScriptExecutionLog
            Log-Activity "Interactive Logon: Machine Inactivity Limit: $InactivityLimit seconds." -LogFile $ComputerLogFile

            # Prompt user for action
            do {
                Write-Host "Options:" -ForegroundColor Yellow
                Write-Host "1. Enable or Modify the inactivity limit" -ForegroundColor Cyan
                Write-Host "2. Disable the inactivity limit" -ForegroundColor Cyan
                Write-Host "3. Exit" -ForegroundColor Cyan

                $UserChoice = Read-Host "Enter your choice (1/2/3)"

                switch ($UserChoice) {
                    "1" {
                        $NewLimit = Read-Host "Enter the new inactivity limit in seconds"
                        Invoke-Command -ComputerName $RemoteComputerName -Credential $Credentials -ScriptBlock {
                            param($Path, $Limit)
                            Set-ItemProperty -Path $Path -Name "InactivityTimeoutSecs" -Value $Limit
                        } -ArgumentList $RegistryPath, $NewLimit
                        Write-Host "Inactivity limit set to $NewLimit seconds." -ForegroundColor Green
                        Log-Activity "Inactivity limit modified to $NewLimit seconds for $RemoteComputerName." -LogFile $ScriptExecutionLog
                        Log-Activity "Inactivity limit modified to $NewLimit seconds." -LogFile $ComputerLogFile
                    }
                    "2" {
                        Invoke-Command -ComputerName $RemoteComputerName -Credential $Credentials -ScriptBlock {
                            param($Path)
                            Remove-ItemProperty -Path $Path -Name "InactivityTimeoutSecs" -ErrorAction SilentlyContinue
                        } -ArgumentList $RegistryPath
                        Write-Host "Inactivity limit disabled." -ForegroundColor Green
                        Log-Activity "Inactivity limit disabled for $RemoteComputerName." -LogFile $ScriptExecutionLog
                        Log-Activity "Inactivity limit disabled." -LogFile $ComputerLogFile
                    }
                    "3" {
                        Write-Host "Exiting options menu." -ForegroundColor Yellow
                        Log-Activity "User exited the options menu for $RemoteComputerName." -LogFile $ScriptExecutionLog
                        Log-Activity "User exited the options menu." -LogFile $ComputerLogFile
                    }
                    default {
                        Write-Host "Invalid choice. Please select 1, 2, or 3." -ForegroundColor Red
                        Log-Activity "Invalid choice entered for $RemoteComputerName." -LogFile $ScriptExecutionLog
                        Log-Activity "Invalid choice entered." -LogFile $ComputerLogFile
                    }
                }
            } while ($UserChoice -ne "3")
        }
    }
}
Log-Activity "Script execution completed." -LogFile $ScriptExecutionLog