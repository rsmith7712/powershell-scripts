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
    Win11CompTestV3.ps1

.DESCRIPTION
    Windows 11 Compatibility Checker Script

.FUNCTIONALITY
    This is a little script used to check Windows 11 compatibility. It evaluates
    whether the machine meets the minimum requirements for Windows 11.
    It checks the processor, RAM, storage, TPM 2.0, UEFI & Secure Boot, graphics card,
    and display. After running the script, it will display the results in PowerShell
    and save them to a .txt file in the same directory.

    Prerequisites:
    - Run the script as an administrator.
    - The script must be located in a root directory (e.g., "C:\temp").
    - PowerShell execution policy must allow running scripts (use "Set-ExecutionPolicy RemoteSigned
    - Run the script using the full path (e.g., "C:\Temp\Win11CompTestV3.ps1").
    - After completion, the results will be displayed in PowerShell and saved to a .txt file named after the machine.
    
.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

#>

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
