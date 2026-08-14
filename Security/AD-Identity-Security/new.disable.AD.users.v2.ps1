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
    new.disable.AD.users.v2.ps1

.DESCRIPTION
    Imports a CSV of AD users to audit their status, disable or enable accounts, and export the results.

.FUNCTIONALITY
    Audits, disables and enables AD users from a CSV.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

<#
This PowerShell script allows list of AD users on the CSV file to be imported for administration 
1.  Import the CSV file
2.  Run the audit to show the AD user status
3.  Disable AD user account
4.  Enable AD usre account
5.  Run the audit and export result to file

#>


#Import CSV
$list = Import-Csv "C:\temp\text\ADUsers.csv"

#Audit current status of AD users on the CSV file
Write-Host "Audit current AD user status" -ForegroundColor Yellow
foreach($entry in $list)
 {
 
$user = $entry.User

Get-ADUser $User -Properties Description | select Name,  Enabled,   SamAccountName

}

#Disables AD users on the CSV file
Write-Host "Disabling AD users on the list" -ForegroundColor Magenta
foreach($entry in $list)
 {
 
$User = $entry.User

Disable-ADAccount -Identity $User

}

#Enalbes AD users on the CSV File
Write-Host "Enabling AD users on the list" -ForegroundColor Blue
foreach($entry in $list)
 {
 
$User = $entry.User

Enable-ADAccount -Identity $User

}


#Audits the AD account status on the CSV file and exports to file
Write-Host "Audit current AD user status" -ForegroundColor Yellow
foreach($entry in $list)
 {
 
$user = $entry.User

Get-ADUser $User -Properties Description | select Name,  Enabled,   SamAccountName | export-csv C:\temp\text\Audit.AD.Accounts.csv -Append

}




