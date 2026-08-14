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
    get-users-older-than-365-days.ps1

.DESCRIPTION
    Lists Active Directory users whose last logon was more than 365 days ago and exports them to a text file.

.FUNCTIONALITY
    Reports users inactive over 365 days.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Import-Module ActiveDirectory

#Set length of time for object back to
$date = (Get-Date).AddDays(-365)

#Query active directory user objects
Get-ADUser -Filter 'LastLogonDate -le $date' -Properties LastLogonDate |`
Select-Object Name,LastLogonDate

#Query active directory user objects and output to text file
Get-ADUser -Filter 'LastLogonDate -le $date' -Properties LastLogonDate |`
Select-Object Name,LastLogonDate | Out-File "C:\temp\orphaned-user-objects-older-than-365-days.txt"