# LEGAL
<# LICENSE
    MIT License, Copyright 2023 Richard Smith

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
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
    Check-Windows-Activation-Status-On-Multiple-Servers.ps1

.DESCRIPTION
    Checks the Windows license and activation status across multiple servers (with a VAMT status reference).

.FUNCTIONALITY
    Checks Windows activation across servers.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

<#
.NAME
    Check-Windows-Activation-Status-On-Multiple-Servers.ps1

.SUMMARY

    Types of WIndows license status
    We all know that there are 2 statuses either it will be
    active or not licensed but let me tell you there are more
    than we can imagine. Let me walk through each of them.

    Status Unknown – Shows all goods for which the VAMT has
    not or is unable to collect licensing status. Any PCs
    that have been added but whose installed products have
    not yet been detected are included in this category.

    Licensed – Shows only products that have been activated
    with a valid product key.

    Out-of-the-Box (OOB) Display all products that are still
    within the initial grace period permitted by Windows,
    Windows Server, or Microsoft Office 2010 prior to required
    activation.

    Non-Genuine Grace – Applicable only to systems running
    Windows Vista RTM edition.  This indicates the system has
    failed online genuine validation and is in 30 day grace
    period.

    Out of Tolerance (OOT) Grace – Display all products that
    have had hardware or BIOS changes significant enough to
    require reactivation, and all KMS client products that have
    not renewed their activation within the 180 days activation
    renewal period.

    Unlicensed – The status of activation cannot be determined.
    It could indicate that activation-related binaries and
    configuration values have been tampered with. This only
    applies to Windows Vista RTM or retail editions of Office 2010.

    Notification – Display all products that have passed the
    activation grace period or have failed validation. These
    products will be subjected to a notification experience but
    will continue to function normally.

    Extended Grace – When we extend the grace period manually.
    Generally a windows server license expires in 180 days.


URL:
    https://powershellguru.com/powershell-script-to-check-windows-activation-status/

#>
Param
(
    [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
    [String[]]$ComputerName = $env:COMPUTERNAME
)
#defined initial data
$LicenseStatus = @("Unlicensed","Activated","OOB Grace",
"OOT Grace","Non-Genuine Grace","Notification","Extended Grace")
$computerName= Get-Content -path "C:\tmp\servers.txt"
Foreach($CN in $ComputerName)
{
    Get-CimInstance -ClassName SoftwareLicensingProduct -ComputerName $CN |`
    Where-Object{$_.PartialProductKey -and $_.Name -like "*Windows*"} | Select-Object `
    @{Expression={$_.PSComputerName};Name="ComputerName"},
    @{Expression={$LicenseStatus[$($_.LicenseStatus)]};Name="LicenseStatus"} | export-csv "C:\tmp\result.csv" -Append
}