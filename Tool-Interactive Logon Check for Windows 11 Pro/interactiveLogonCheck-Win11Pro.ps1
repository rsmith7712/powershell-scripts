<#


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

2024-12-16:[CREATED]
    Time for troubleshooting and updates.
#>

# Ensure the PowerShell script runs in Administrator mode
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Please run this script as an Administrator." -ForegroundColor Red
    exit
}

# Initialize log file
$LogFile = "C:\Temp\InteractiveLogonScriptLog_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"
function Log-Activity {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "$Timestamp - $Message"
    Add-Content -Path $LogFile -Value $LogMessage
}

Log-Activity "Script started."

# Prompt user for Domain Administrator credentials
$Credentials = Get-Credential -Message "Enter Domain Administrator credentials"
Log-Activity "User entered credentials."

# Input remote computer name
$RemoteComputerName = Read-Host "Enter the remote computer name"
Log-Activity "Remote computer name entered: $RemoteComputerName"

# Verify if the remote computer is reachable
if (-not (Test-Connection -ComputerName $RemoteComputerName -Count 1 -Quiet)) {
    Write-Host "The remote computer is not reachable." -ForegroundColor Red
    Log-Activity "Remote computer $RemoteComputerName is not reachable. Script exiting."
    exit
}

# Check the operating system of the remote computer
$OSInfo = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $RemoteComputerName -Credential $Credentials

if ($OSInfo) {
    $OSName = $OSInfo.Caption
    Log-Activity "Operating system retrieved: $OSName"
    if ($OSName -match "Windows 11 Pro") {
        Write-Host "The remote computer is running Windows 11 Pro." -ForegroundColor Green
        Log-Activity "The remote computer is running Windows 11 Pro."

        # Get the Interactive Logon: Machine Inactivity Limit setting from the registry
        $RegistryPath = "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\System"
        $RegistryKey = Invoke-Command -ComputerName $RemoteComputerName -Credential $Credentials -ScriptBlock {
            Get-ItemProperty -Path $using:RegistryPath -Name "InactivityTimeoutSecs" -ErrorAction SilentlyContinue
        }

        $InactivityLimit = if ($RegistryKey.InactivityTimeoutSecs) {
            $RegistryKey.InactivityTimeoutSecs
        }
        else {
            "Not Configured"
        }

        # Display the result in the console
        Write-Host "Interactive Logon: Machine Inactivity Limit: $InactivityLimit seconds" -ForegroundColor Cyan
        Log-Activity "Inactivity Limit retrieved: $InactivityLimit seconds"

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
                        Set-ItemProperty -Path $using:RegistryPath -Name "InactivityTimeoutSecs" -Value $using:NewLimit
                    }
                    Write-Host "Inactivity limit set to $NewLimit seconds." -ForegroundColor Green
                    Log-Activity "Inactivity limit modified to $NewLimit seconds."
                }
                "2" {
                    Invoke-Command -ComputerName $RemoteComputerName -Credential $Credentials -ScriptBlock {
                        Remove-ItemProperty -Path $using:RegistryPath -Name "InactivityTimeoutSecs" -ErrorAction SilentlyContinue
                    }
                    Write-Host "Inactivity limit disabled." -ForegroundColor Green
                    Log-Activity "Inactivity limit disabled."
                }
                "3" {
                    Write-Host "Exiting." -ForegroundColor Yellow
                    Log-Activity "User chose to exit."
                }
                default {
                    Write-Host "Invalid choice. Please select 1, 2, or 3." -ForegroundColor Red
                }
            }
        } while ($UserChoice -ne "3")

        # Ensure C:\Temp exists
        $ExportPath = "C:\Temp"
        if (-not (Test-Path -Path $ExportPath)) {
            New-Item -Path $ExportPath -ItemType Directory | Out-Null
        }

        # Export results to a CSV file
        #$DateTime = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $ExportFile = "$ExportPath\InactivityLimitResults_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').csv"
        $Results = [PSCustomObject]@{
            ComputerName        = $RemoteComputerName
            OperatingSystem     = $OSName
            InactivityLimitSecs = $InactivityLimit
        }
        $Results | Export-Csv -Path $ExportFile -NoTypeInformation -Force

        Write-Host "Results exported to $ExportFile" -ForegroundColor Green
        Log-Activity "Results exported to $ExportFile."
    }
    else {
        Write-Host "The remote computer is running: $OSName" -ForegroundColor Yellow
        Log-Activity "The remote computer is running: $OSName."
    }
}
else {
    Write-Host "Failed to retrieve the operating system information for $RemoteComputerName." -ForegroundColor Red
    Log-Activity "Failed to retrieve operating system information for $RemoteComputerName."
}
Log-Activity "Script completed."