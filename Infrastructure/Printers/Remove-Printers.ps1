# LEGAL
<# LICENSE
    MIT License, Copyright 2018 Richard Smith

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
    Remove-Printers.ps1

.DESCRIPTION
    Removes printers and reboots computers flagged for manual check in a CSV, using background jobs (WMI).

.FUNCTIONALITY
    Removes printers and reboots flagged computers.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$Data = Import-Csv

$Data = $Data | Where-Object{$_.Printer -eq "Manual Check Required"}

$SB = {
    Get-WmiObject -ComputerName $args -Class win32_printer | ForEach-Object{$_.delete()}
    Start-Sleep 1
    Restart-Computer -ComputerName $args -Force
    }

ForEach($Line in $Data){
    $running = @(Get-Job | Where-Object {$_.State -eq 'Running' })
    if ($running.Count -le 20){
        Start-Job -ScriptBlock $SB -ArgumentList $Line.Computer | Out-Null
        }
    Else {
        $running | Wait-Job
        }
    }