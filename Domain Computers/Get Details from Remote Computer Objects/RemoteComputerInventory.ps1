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
    RemoteComputerInventory.ps1

.SYNOPSIS
    Query remote computers for specific inventory data and dump to a csv

.FUNCTIONALITY

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Import Active Directory module
Import-Module ActiveDirectory

# Prompt for Domain Admin credentials
$cred = Get-Credential -Message 'Enter Domain Admin credentials for remote CIM queries'

# Establish Export and Logging Variables
$exportPath = 'C:\Temp\RemoteComputerInventory.csv'
$logPath    = 'C:\Temp\RemoteComputerInventory.log'

# Logging Function
function Write-Log {
    param(
        [string]$Message,
        [switch]$IsError
    )
    $ts     = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $level  = if ($IsError) { 'ERROR' } else { 'INFO' }
    $entry  = "$ts [$level] $Message"

    if ($IsError) {
        Write-Host $entry -ForegroundColor Red
    } else {
        Write-Host $entry -ForegroundColor Gray
    }

    $entry | Out-File -FilePath $logPath -Append -Encoding utf8
}

"`n==== Script started at $(Get-Date) ====" | Out-File $logPath -Encoding utf8

# Retrieve all computer names from Active Directory
$computers = Get-ADComputer -Filter * | Select-Object -Expand Name

$results = foreach ($comp in $computers) {

    if (-not (Test-Connection -ComputerName $comp -Count 1 -Quiet)) {
        Write-Log "[$comp] Offline or not responding to ping." -IsError
        [PSCustomObject]@{
            DNSHostName            = $comp
            OperatingSystem        = $null
            OperatingSystemVersion = $null
            Uptime                 = $null
            Online                 = $false
            CurrentUser            = $null
            Manufacturer           = $null
            Model                  = $null
            SerialNumber           = $null
            ErrorMessage           = 'Ping failed'
        }
        continue
    }

    try {
        $opt = New-CimSessionOption -Protocol Dcom
        $cs  = New-CimSession -ComputerName $comp -Credential $cred -SessionOption $opt -ErrorAction Stop
        Write-Log "[$comp] CIM session created."
    }
    catch {
        Write-Log "[$comp] Failed to create CIM session: $($_.Exception.Message)" -IsError
        [PSCustomObject]@{
            DNSHostName            = $comp
            OperatingSystem        = $null
            OperatingSystemVersion = $null
            Uptime                 = $null
            Online                 = $true
            CurrentUser            = $null
            Manufacturer           = $null
            Model                  = $null
            SerialNumber           = $null
            ErrorMessage           = "CIM session error: $($_.Exception.Message)"
        }
        continue
    }

    try {
        $os   = Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $cs -ErrorAction Stop
        $sys  = Get-CimInstance -ClassName Win32_ComputerSystem  -CimSession $cs -ErrorAction Stop
        $bios = Get-CimInstance -ClassName Win32_BIOS           -CimSession $cs -ErrorAction Stop

        [PSCustomObject]@{
            DNSHostName            = $comp
            OperatingSystem        = $os.Caption
            OperatingSystemVersion = $os.Version
            Uptime                 = ([datetime]::Now - $os.LastBootUpTime).ToString('dd\.hh\:mm\:ss')
            Online                 = $true
            CurrentUser            = $sys.UserName
            Manufacturer           = $sys.Manufacturer
            Model                  = $sys.Model
            SerialNumber           = $bios.SerialNumber
            ErrorMessage           = $null
        }
    }
    catch {
        Write-Log "[$comp] CIM query failed: $($_.Exception.Message)" -IsError
        [PSCustomObject]@{
            DNSHostName            = $comp
            OperatingSystem        = '<error>'
            OperatingSystemVersion = '<error>'
            Uptime                 = '<error>'
            Online                 = $true
            CurrentUser            = '<error>'
            Manufacturer           = '<error>'
            Model                  = '<error>'
            SerialNumber           = '<error>'
            ErrorMessage           = $_.Exception.Message
        }
    }
    finally {
        if ($cs) { $cs | Remove-CimSession }
    }
}
# Export results to CSV
$results | Export-Csv -Path $exportPath -NoTypeInformation
Write-Log "Exported results to $exportPath."
Write-Host "Done – see log at $logPath and CSV at $exportPath."