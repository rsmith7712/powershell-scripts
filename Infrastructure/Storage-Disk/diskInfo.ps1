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
    diskInfo.ps1

.DESCRIPTION
    Reports fixed logical disk information for a target computer via WMI (documented function).

.FUNCTIONALITY
    Reports fixed disk information.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Function Get-FixedDisk {
    [CmdletBinding()]
    # This param() block indicates the start of parameters declaration
    param (
        <#
            This parameter accepts the name of the target computer.
            It is also set to mandatory so that the function does not execute without specifying the value.
        #>
        [Parameter(Mandatory)]
        [string]$Computer
    )
    <#
        WMI query command which gets the list of all logical disks and saves the results to a variable named $DiskInfo
    #>
    #$DiskInfo = Get-WmiObject Win32_LogicalDisk -ComputerName $Computer -Filter 'DriveType=3'
    $DiskInfo = Get-CimInstance Win32_LogicalDisk #
   $DiskInfo
}