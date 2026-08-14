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
    fGet-UserEmailAddresses.ps1

.DESCRIPTION
    Counts Active Directory accounts that have email addresses across the corporate, store-user and store-manager OUs.

.FUNCTIONALITY
    Reports email-address counts by AD organizational unit.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Anyone with a domain email address
# -------------------------------------------------------------------------------
## Corporate - any account with an employeeID
(Get-ADUser -Filter "EmployeeID -like '*'" -Properties EmailAddress).EmailAddress.count

## Store Accounts - any user object under the Store Accounts OU
$storeOU = "OU=Store Users,OU=Store Accounts,DC=DOMAIN,DC=com"
(Get-ADUser -Filter "ObjectClass -like 'user'" -SearchBase $storeOU -Properties EmailAddress).EmailAddress.count

## Store Managers - any user object under the Store Managers OU
$managerOU = "OU=Store Managers,OU=Store Accounts,DC=DOMAIN,DC=com"
(Get-ADUser -Filter "ObjectClass -like 'user'" -SearchBase $managerOU -Properties EmailAddress).EmailAddress.count