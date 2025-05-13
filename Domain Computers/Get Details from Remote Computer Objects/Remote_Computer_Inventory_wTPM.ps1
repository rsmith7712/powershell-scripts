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
    Remote_Computer_Inventory_wTPM.ps1

.SYNOPSIS
    Queries remote computers for OS, system, and TPM information using Domain
    Admin credentials and exports results to CSV

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
$exportPath = 'C:\Temp\Remote_Computer_Inventory_wTPM.csv'
$logPath    = 'C:\Temp\Remote_Computer_Inventory_wTPM.log'

# Ensure output folder exists
$folder = Split-Path $exportPath
if (-not (Test-Path $folder)) { New-Item -Path $folder -ItemType Directory | Out-Null }

# Logging Function
function Write-Log {
    param(
        [string]$Message,
        [switch]$IsError
    )
    $ts     = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $level  = if ($IsError) { 'ERROR' } else { 'INFO' }
    $entry  = "$ts [$level] $Message"

    if ($IsError) { Write-Host $entry -ForegroundColor Red } else { Write-Host $entry -ForegroundColor Gray }
    $entry | Out-File -FilePath $logPath -Append -Encoding utf8
}

"`n==== Script started at $(Get-Date) ====" | Out-File $logPath -Encoding utf8

# Retrieve all computer names from Active Directory
$computers = Get-ADComputer -Filter * | Select-Object -ExpandProperty Name

$results = @()

foreach ($comp in $computers) {
    # Initialize CimSession variable
    $cs = $null

    try {
        # AD, DNS, and Ping checks
        $adComputer  = Get-ADComputer -Filter "Name -eq '$comp'" -Properties LastLogonTimeStamp -ErrorAction SilentlyContinue
        $dnsResult   = Resolve-DnsName -Name $comp -ErrorAction SilentlyContinue
        $pingResult  = Test-Connection -ComputerName $comp -Count 1 -Quiet

        $lastLogon = if ($adComputer) {
            if ($adComputer.LastLogonTimeStamp) {
                ([DateTime]::FromFileTime($adComputer.LastLogonTimeStamp)).ToString('yyyy-MM-dd HH:mm')
            } else { 'Never Logged On' }
        } else { 'Not Found in AD' }

        # Ping offline case
        if (-not $pingResult) {
            Write-Log "[$comp] Offline or not responding to ping." -IsError
            $results += [PSCustomObject]@{
                ComputerName    = $comp
                Uptime          = $null
                CurrentUser     = $null
                LastLogon       = $lastLogon
                OperatingSystem = $null
                OSVersion       = $null
                Manufacturer    = $null
                Model           = $null
                SerialNumber    = $null
                TPMPresent      = $null
                TPMReady        = $null
                ExistsInAD      = [bool]$adComputer
                ExistsInDNS     = ($dnsResult -ne $null)
                PINGABLE        = $false
                ErrorMessage    = 'Ping failed'
            }
            continue
        }

        # Establish CIM session
        $opt = New-CimSessionOption -Protocol Dcom
        $cs  = New-CimSession -ComputerName $comp -Credential $cred -SessionOption $opt -ErrorAction Stop
        Write-Log "[$comp] CIM session created."

        # Query remote data
        $os   = Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $cs -ErrorAction Stop
        $sys  = Get-CimInstance -ClassName Win32_ComputerSystem  -CimSession $cs -ErrorAction Stop
        $bios = Get-CimInstance -ClassName Win32_BIOS            -CimSession $cs -ErrorAction Stop
        $tpm  = Get-CimInstance `
                  -Namespace 'root\CIMv2\Security\MicrosoftTpm' `
                  -ClassName Win32_Tpm `
                  -CimSession $cs `
                  -ErrorAction Stop

        # Add to results
        $results += [PSCustomObject]@{
            ComputerName    = $comp
            Uptime          = ([datetime]::Now - $os.LastBootUpTime).ToString('dd\.hh\:mm\:ss')
            CurrentUser     = $sys.UserName
            LastLogon       = $lastLogon
            OperatingSystem = $os.Caption
            OSVersion       = $os.Version
            Manufacturer    = $sys.Manufacturer
            Model           = $sys.Model
            SerialNumber    = $bios.SerialNumber
            TPMPresent      = $tpm.IsEnabled_InitialValue
            TPMReady        = $tpm.IsActivated_InitialValue
            ExistsInAD      = [bool]$adComputer
            ExistsInDNS     = ($dnsResult -ne $null)
            PINGABLE        = $true
            ErrorMessage    = $null
        }
    }
    catch {
        Write-Log "[$comp] Error processing: $($_.Exception.Message)" -IsError
        $results += [PSCustomObject]@{
            ComputerName    = $comp
            Uptime          = '<error>'
            CurrentUser     = '<error>'
            LastLogon       = "Error: $($_.Exception.Message)"
            OperatingSystem = '<error>'
            OSVersion       = '<error>'
            Manufacturer    = '<error>'
            Model           = '<error>'
            SerialNumber    = '<error>'
            TPMPresent      = '<error>'
            TPMReady        = '<error>'
            ExistsInAD      = $false
            ExistsInDNS     = $false
            PINGABLE        = $false
            ErrorMessage    = $_.Exception.Message
        }
    }
    finally {
        if ($cs) { Remove-CimSession $cs }
    }
}

# Export results to CSV
$results | Export-Csv -Path $exportPath -NoTypeInformation
Write-Log "Exported results to $exportPath."
Write-Host "Done – see log at $logPath and CSV at $exportPath."
