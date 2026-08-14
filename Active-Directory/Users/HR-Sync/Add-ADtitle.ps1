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
    Add-ADtitle.ps1

.DESCRIPTION
    Reads a CSV of users and populates each row's Title from the matching Active Directory account (looked up by email address), then re-exports the CSV.

.FUNCTIONALITY
    Adds AD job titles to a user CSV.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$Users = Import-CSV C:\users\user4-admin\desktop\AX_EnabledUsers.csv

ForEach($User in $Users){
    $Title = (Get-ADUser -Filter "EmailAddress -eq '$($User.email)'" -Properties EmailAddress, Title).title
    $User.Title = $Title
}
$Users | Export-CSV C:\Users\user4-admin\desktop\AX_EnabledUsers_Updated.csv