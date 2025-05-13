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
    RemoteComputerTPMCheck.ps1

.SYNOPSIS
    Queries remote computers for OS, system, and TPM information using Domain
    Admin credentials and exports results to CSV

.FUNCTIONALITY

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Prompt for Domain Admin credentials
$cred = Get-Credential -Message "Enter Domain Admin Credentials"

# Import Active Directory module (requires RSAT tools)
Import-Module ActiveDirectory -ErrorAction Stop

# Retrieve all computer names from Active Directory
$computers = Get-ADComputer -Filter * | Select-Object -ExpandProperty Name

# Initialize collection for results
$results = @()

foreach ($computer in $computers) {
    Write-Host "Querying $computer..." -ForegroundColor Cyan
    try {
        # Query OS details
        $os = Invoke-Command -ComputerName $computer -Credential $cred -ScriptBlock {
            Get-CimInstance -ClassName Win32_OperatingSystem |
                Select-Object Caption, OSArchitecture, Version
        } -ErrorAction Stop

        # Query comprehensive computer info
        $info = Invoke-Command -ComputerName $computer -Credential $cred -ScriptBlock {
            Get-ComputerInfo |
                Select-Object WindowsProductName, WindowsVersion, OsHardwareAbstractionLayer, SystemProductName, SystemManufacturer
        } -ErrorAction Stop

        # Query TPM status
        $tpm = Invoke-Command -ComputerName $computer -Credential $cred -ScriptBlock {
            Get-TPM |
                Select-Object TpmPresent, TpmReady
        } -ErrorAction Stop

        # Build result object
        $results += [PSCustomObject]@{
            ComputerName                = $computer
            Caption                     = $os.Caption
            OSArchitecture              = $os.OSArchitecture
            Version                     = $os.Version
            WindowsProductName          = $info.WindowsProductName
            WindowsVersion              = $info.WindowsVersion
            OsHardwareAbstractionLayer  = $info.OsHardwareAbstractionLayer
            SystemProductName           = $info.SystemProductName
            SystemManufacturer          = $info.SystemManufacturer
            TPMPresent                  = $tpm.TpmPresent
            TPMReady                    = $tpm.TpmReady
        }
    }
    catch {
        Write-Warning "Failed to query ${computer}:`n$_"
    }
}
# Export results to CSV
$exportPath = "C:\temp\RemoteComputersInfo.csv"
$results | Export-Csv -Path $exportPath -NoTypeInformation -Force

Write-Host "Results exported to $exportPath" -ForegroundColor Green