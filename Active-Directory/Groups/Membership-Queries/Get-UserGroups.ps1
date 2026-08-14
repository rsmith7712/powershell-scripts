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
    Get-UserGroups.ps1

.DESCRIPTION
    Prompts for a user name and writes that user's Active Directory group memberships to a text file, then opens it.

.FUNCTIONALITY
    Lists a user's AD group memberships to a file.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$varUsr = Read-Host "Username"
if((Test-Path "C:\Users\sysadmin\Desktop") -eq $false){md "C:\Users\sysadmin\Desktop"}
$outfile = "C:\Users\sysadmin\Desktop\AdUsrTMP.txt"
if(Test-Path $outfile){rd $outfile}
Import-Module ActiveDirectory -Force
(Get-ADPrincipalGroupMembership $varUsr).name | foreach {"$_; " | Out-File $outfile -NoNewline -Append}
Invoke-Item $outfile