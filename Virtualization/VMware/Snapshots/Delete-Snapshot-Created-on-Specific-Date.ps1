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
    Delete-Snapshot-Created-on-Specific-Date.ps1

.DESCRIPTION
    Connects to vCenter and removes a VM's snapshots created on a specific date.

.FUNCTIONALITY
    Deletes VM snapshots by creation date.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

<#
.NAME
    Delete-Snapshot-Created-on-Specific-Date.ps1
.SUMMARY
    Limit snapshot removal to those created on a specific date
#>

Connect-VIServer -Server "srvvcenterp.example.com" -Protocol https

# Target specific VM
$targetDate = '12/6/2022'
$date = Get-Date $targetDate
Get-VM -Name WinServer2016 | Get-Snapshot | where{$_.Created.Date -eq $date} | Remove-Snapshot #-Confirm:$false


# Target against list
<#
$targetDate = '7/23/2022'
$date = Get-Date $targetDate
#$vmNames = Get-Content -Path c:\temp\vmnames.txt
#Get-VM -Name $vmNames | Get-Snapshot | where{$_.Created.Date -eq $date} | Remove-Snapshot #-Confirm:$false
#>


# Limit the removal to snapshots with a specific text in the Description, you could do
<#
$targetText = 'Enter Target Text Here'
$vmNames = Get-Content -Path c:\temp\vmnames.txt
Get-VM -Name $vmNames | Get-Snapshot | where{$_.Description -match $targetText} | Remove-Snapshot #-Confirm:$false
#>