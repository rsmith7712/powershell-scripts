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
    Function-QuerySQL-Server-ForDriveSpace.ps1

.DESCRIPTION
    Reports the local drive space (total and free) on a prompted SQL server via WMI (Win32_LogicalDisk).

.FUNCTIONALITY
    Reports drive space on a SQL server.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

<#
Simplest way to get the disk space information is with 
the Win32_LogicalDisk class. We filter the content to 
pick only DriveType=3 which is the type number for 
local drives.
#>

$SQLServers = Read-Host -Prompt "Enter SQL server to query for drive space: "

Get-WmiObject win32_logicaldisk -ComputerName $SQLServers -Filter "Drivetype=3" |`
select  SystemName,DeviceID,VolumeName,@{Label="Total Size";Expression={$_.Size / 1gb -as [int] }},@{Label="Free Size";Expression={$_.freespace / 1gb -as [int] }}|Format-Table -AutoSize
