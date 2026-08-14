# LEGAL
<# LICENSE
    MIT License, Copyright 2022 Richard Smith

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
    fDisable-Schtasks.ps1

.DESCRIPTION
    Disables a named scheduled task across all enabled store CORE computers in Active Directory.

.FUNCTIONALITY
    Disables a scheduled task across store computers.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$computerCount = @()
$exceptionCount = @()
$tn = "Backup GlobalSTORE to SharePoint"
$coreObjs = Get-ADComputer -Filter {Name -like '*core' -and Enabled -eq 'True'}
$computerCount = $coreObjs.count
$coreObjs |
ForEach-Object{
    $target = $_.Name
    Write-Host $target -ForegroundColor Yellow
    $ErrorActionPreference = "Stop"
    Try
    {
        #schtasks /change /s $target /tn $tn /disable
        schtasks /query /s $target /tn $tn
    }
        Catch
        {
            Write-Host "[EXCEPTION] : The following exception occured: $($_.Exception.Message)" -foregroundcolor "cyan"
            $exceptionCount++
        }
    $ErrorActionPreference = "Continue"

}
Write-Host "Total Core computers: $($computerCount)`nExceptions: $($exceptionCount)" -ForegroundColor White -BackgroundColor Blue



