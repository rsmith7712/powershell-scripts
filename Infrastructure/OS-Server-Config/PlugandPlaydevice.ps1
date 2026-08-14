# LEGAL
<# LICENSE
    MIT License, Copyright 2015 Richard Smith

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
    PlugandPlaydevice.ps1

.DESCRIPTION
    Enumerates Plug-and-Play (Win32_PnPEntity) devices on a prompted remote computer.

.FUNCTIONALITY
    Lists Plug-and-Play devices on a remote computer.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$computers = Read-Host "Enter Computer Name"

$arrcomputers = $computers
foreach ($computer in $arrcomputers)
{
Write-Host ""
Write-Host "==========================="
Write-Host "Computer: $computer"
Write-Host "==========================="

Write-Host "---------------------------"
Write-Host "Win32_PnPEntity Instance"
Write-Host "---------------------------"

$colitems = Get-WmiObject -class win32_PnPEntity -Namespace "root\cimv2" -computer $computer
$colitems[0..47] | format-list name, status
}