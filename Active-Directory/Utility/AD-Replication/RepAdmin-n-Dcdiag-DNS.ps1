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
    RepAdmin-n-Dcdiag-DNS.ps1

.DESCRIPTION
    Runs a replication summary, DCDiag (including the DNS test) and collects Directory Service security events for domain controllers (administrator required).

.FUNCTIONALITY
    Runs repadmin, DCDiag and event checks on DCs.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#Requires -RunAsAdministrator
<# RepAdmin-n-Dcdiag-DNSs.ps1 #>
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){
        Write-Output "This script needs to be run As Admin"
        Break}
Import-Module ActiveDirectory
repadmin /replsum srv > c:\temp\repadm-sumnary.txt
DCDiag /e /v /s:srv > c:\temp\dcdiag-full-report.txt
DCDiag /Test:DNS /e /v /s:srv > c:\temp\dcdiag-dns-summary.txt

$Machine = "srv"
Get-Eventlog -Logname Security -ComputerName $Machine -newest 1000 |
Where-Object {$_.EventID -eq '2886'} |
Format-Table MachineName, Source, EventID -auto > c:\temp\eventvwr-2886-summary.txt
echo "If no results displayed, this is a good thing!"