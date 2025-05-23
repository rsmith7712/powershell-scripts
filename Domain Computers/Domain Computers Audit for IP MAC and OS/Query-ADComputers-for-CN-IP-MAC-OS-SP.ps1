﻿﻿# LEGAL
<# LICENSE
    MIT License, Copyright 2024 Richard Smith

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
.DESCRIPTION
  Query-ADComputers-for-CN-IP-MAC-OS-SP.ps1

.FUNCTIONALITY
  1. Use PowerShell and the AD module 
    to get a listing of computers and IP addresses

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
		
#>

$results = Get-ADComputer -Filter * -Properties ipv4Address, MacAddress, OperatingSystem, OperatingSystemServicePack | Format-List name, ipv4*, mac*, oper*
$results | Out-File C:\temp\AD-Systems-n-IPs.txt
#$results | Export-Csv C:\temp\AD-Systems-n-IPs.csv -NoTypeInformation