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
    interactiveLogonCheck.ps1

.DESCRIPTION
    This script is designed to check the "Interactive Logon: Machine Inactivity Limit"
    registry setting on a remote computer. It prompts the user for domain administrator
    credentials, accepts a remote computer name as input, and retrieves the registry
    setting value. The script also provides options to enable, modify, or disable the
    setting and logs all activities and results.

.FUNCTIONALITY
    This script is intended for use in a domain environment to check and manage the
    "Interactive Logon: Machine Inactivity Limit" setting on remote computers. It is
    useful for administrators who want to ensure that this security setting is configured
    according to their organization's policies.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

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
        Log-Activity "Operating system retrieved for ${RemoteComputerName}: $OSName." -LogFile $ScriptExecutionLog
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
            Log-Activity "Inactivity Limit retrieved for ${RemoteComputerName}: $InactivityLimit seconds." -LogFile $ScriptExecutionLog
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