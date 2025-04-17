# Windows 11 Compatibility Checker Script
# This script checks if a machine meets the minimum requirements for Windows 11.
# Requires -RunAsAdministrator.
# It must be inside a root directory; "C:\temp" is known to work.
# PS1 execution must not be restricted. 
# Run "Set-ExecutionPolicy RemoteSigned" then "Y" to ensure PS1 file execution is enabled.
# If the PS1 file is located inside the temp folder, use "C:\Temp\Win11CompTestV3.ps1" to run the test.
# After completion, test results will be displayed in PowerShell. 
# The script will also create a .txt file named after the machine name with the results in the same folder where it was run.


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

function Main {
    Write-Host "Checking Windows 11 Compatibility..." -ForegroundColor Cyan
    Write-Host "------------------------------------"

    $checks = @{
        "Processor"       = Check-Processor
        "RAM"            = Check-RAM
        "Storage"        = Check-Storage
        "TPM 2.0"        = Check-TPM
        "UEFI & Secure Boot" = Check-UEFI-SecureBoot
        "Graphics Card"  = Check-Graphics
        "Display"        = Check-Display
    }

    $allPassed = $true
    $results = @()

    foreach ($check in $checks.GetEnumerator()) {
        $status = if ($check.Value) { 
            "PASS" 
        } else { 
            "FAIL" 
            Write-Host "$($check.Key) Check Failed" -ForegroundColor Yellow
            switch ($check.Key) {
                "Processor" { Write-Host "Your processor must have at least 2 cores and a speed of 1 GHz or higher." }
                "RAM" { Write-Host "Your computer needs at least 4 GB of RAM." }
                "Storage" { Write-Host "Your computer requires at least 64 GB of storage space." }
                "TPM 2.0" { Write-Host "TPM 2.0 must be enabled." }
                "UEFI & Secure Boot" { Write-Host "UEFI firmware and Secure Boot must be enabled." }
                "Graphics Card" { Write-Host "Your graphics card must support DirectX 12 or newer with WDDM 2.0 driver." }
            }
        }

        $results += "$($check.Key): $status"
        Write-Host "$($check.Key): $status"
        if (-not $check.Value) {
            $allPassed = $false
        }
    }

    $pcName = (Get-WmiObject -Class Win32_ComputerSystem).Name
    $resultsFile = "$PSScriptRoot\$pcName-CompatibilityResults.txt"
    $results | Out-File -FilePath $resultsFile -Encoding utf8

    if ($allPassed) {
        Write-Host "`nYour computer is compatible with Windows 11!" -ForegroundColor Green
        $results += "`nYour computer is compatible with Windows 11!"
    } else {
        Write-Host "`nYour computer does not meet all the requirements for Windows 11." -ForegroundColor Red
        $results += "`nYour computer does not meet all the requirements for Windows 11."
    }

    $results | Out-File -FilePath $resultsFile -Encoding utf8
}

# Run the main function
Main
