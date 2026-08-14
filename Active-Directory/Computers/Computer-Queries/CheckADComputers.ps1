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
    CheckADComputers.ps1

.DESCRIPTION
    Queries Active Directory for computer accounts whose LastLogonDate is older than a 30-day cutoff and exports Name, operating system, version, last logon date and canonical name to CSV.

.FUNCTIONALITY
    Reports stale or inactive AD computer accounts for cleanup review.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Import-Module ActiveDirectory

# get today's date
$today = Get-Date

#Get today - 60 days (2 month old)
$cutoffdate = $today.AddDays(-30)

#Get the computer accounts filtered by lastlogondate.
# Select only required properties of the computer account
# and export it to a file
Get-ADComputer  -Properties * -Filter {LastLogonDate -lt $cutoffdate} `
| Select Name,OperatingSystem,OperatingSystemVersion, `
LastLogonDate,CanonicalName | Export-Csv C:\Users\user5\Desktop\ActiveComputers.csv