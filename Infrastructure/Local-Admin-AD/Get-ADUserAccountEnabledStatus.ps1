# LEGAL
<# LICENSE
    MIT License, Copyright 2017 Richard Smith

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
    Get-ADUserAccountEnabledStatus.ps1

.DESCRIPTION
    Reports the enabled status of store accounts read from an investigation list (with a commented-out inline store list).

.FUNCTIONALITY
    Reports AD account enabled status.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$txtfile = '\\SERVER\SHARE\...\investigate_these.txt'
$stores = Get-Content $txtfile

<#
$stores = @(
"1134",
"1135",
"1148",
"1219",
"1221",
"1227",
"1380",
"1003"
)
#>
$stores|
    ForEach-Object{
    Try
    {
        $str = $_ + "STR"
        $mgr = $_ + "MGR"
        $strQuery = Get-ADUser -Identity $str
        $mgrQuery = Get-ADUser -Identity $mgr
        $strAcctStatus = $strQuery.Enabled
        $mgrAcctStatus = $mgrQuery.Enabled
        Write-Host "UFO_NUMBER: $_" -ForegroundColor White -BackgroundColor Blue
        Write-Host "$str [Status] : Enabled = $strAcctStatus"-ForegroundColor White
        Write-Host "$mgr [Status] : Enabled = $mgrAcctStatus"-ForegroundColor White
    }
        Catch
        {
            Write-Host "[ERROR] : The following exception occurred: $($_.Exception.Message)." -ForegroundColor White -BackgroundColor Red
        }
    }
