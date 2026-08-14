# LEGAL
<# LICENSE
    MIT License, Copyright 2021 Richard Smith

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
    fGet-LocalAdminWMIObject.ps1

.DESCRIPTION
    Enumerates local user accounts on a computer via WMI and locates the built-in Administrator account by SID.

.FUNCTIONALITY
    Reports local accounts and the built-in admin.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$computerObj = $env:COMPUTERNAME

$userObjs = Get-WmiObject -ComputerName $computerObj -Class Win32_UserAccount -Filter "LocalAccount=True" -Property *
$userObjs.Name | ForEach-Object {
    $values = @{
    computer = $userObjs.PScomputerName
    account = $userObjs.Name
    sid = $userObjs.SID
    }
}
$values | foreach{get-wmiobject -class Win32_UserAccount -Filter "SID = 'S-1-5-21-368715379-1463008823-262193891-500'"}