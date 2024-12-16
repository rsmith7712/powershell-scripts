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

#>

# Ensure the PowerShell script runs in Administrator mode
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Please run this script as an Administrator." -ForegroundColor Red
    exit
}
# Prompt user for Domain Administrator credentials
$Credentials = Get-Credential -Message "Enter Domain Administrator credentials"

# Input remote computer name
$RemoteComputerName = Read-Host "Enter the remote computer name"

# Verify if the remote computer is reachable
if (-not (Test-Connection -ComputerName $RemoteComputerName -Count 1 -Quiet)) {
    Write-Host "The remote computer is not reachable." -ForegroundColor Red
    exit
}
# Check the operating system of the remote computer
$OSInfo = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $RemoteComputerName -Credential $Credentials

if ($OSInfo) {
    $OSName = $OSInfo.Caption
    if ($OSName -match "Windows 11 Pro") {
        Write-Host "The remote computer is running Windows 11 Pro." -ForegroundColor Green
        # Get the Interactive Logon: Machine Inactivity Limit setting from the registry
        $RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        $RegistryKey = Get-ItemProperty -Path $RegistryPath -Name "InactivityTimeoutSecs" -ErrorAction SilentlyContinue -Credential $Credentials -ComputerName $RemoteComputerName
        $InactivityLimit = if ($RegistryKey.InactivityTimeoutSecs) {
            $RegistryKey.InactivityTimeoutSecs
        } else {
            "Not Configured"
        }
        # Display the result in the console
        Write-Host "Interactive Logon: Machine Inactivity Limit: $InactivityLimit seconds" -ForegroundColor Cyan
        # Ensure C:\Temp exists
        $ExportPath = "C:\Temp"
        if (-not (Test-Path -Path $ExportPath)) {
            New-Item -Path $ExportPath -ItemType Directory | Out-Null
        }
        # Export results to a CSV file
        $DateTime = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $ExportFile = "$ExportPath\$DateTime_InactivityLimitResults.csv"
        $Results = [PSCustomObject]@{
            ComputerName        = $RemoteComputerName
            OperatingSystem     = $OSName
            InactivityLimitSecs = $InactivityLimit
        }
        $Results | Export-Csv -Path $ExportFile -NoTypeInformation -Force
        Write-Host "Results exported to $ExportFile" -ForegroundColor Green
    } else {
        Write-Host "The remote computer is running: $OSName" -ForegroundColor Yellow
    }
} else {
    Write-Host "Failed to retrieve the operating system information for $RemoteComputerName." -ForegroundColor Red
}