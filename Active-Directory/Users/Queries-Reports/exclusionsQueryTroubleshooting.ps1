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
    exclusionsQueryTroubleshooting.ps1

.DESCRIPTION
    Queries Active Directory users and exports results to CSV, filtered by date, for troubleshooting account-exclusion logic.

.FUNCTIONALITY
    Troubleshooting query of AD users to CSV.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>



# Import Modules Needed
Import-Module ActiveDirectory

# Output results to CSV file
$LogFile = "C:\ExclusionsQuery-USERS.csv"

# Today's Date
$today = get-date -uformat "%Y/%m/%d"
 
# Date to search by
$xDays = (get-date).AddDays(-90)
 
# Expiration date
$expire = (get-date).AddDays(-1)

# Sets the OU to do the base search for all user accounts, change as required
$SearchBase = "DC=Domain, DC=com"

# Sets the Exclusion OU
$ExclusionOU = "OU=Users, OU=Service Accounts, OU=Domain Services, DC=Domain, DC=com"


# ############################################# 

# Example - All the users from the evil OU:
#$SearchBase = $computers| ? {$_.DistinguishedName -like "*DC=Domain, DC=com*"}

# Example - All the users EXCEPT the ones from the evil OU:
#$ExclusionOU = $computers| ? {$_.DistinguishedName -notlike "*ou=Service Accounts,*"}

# Example - All the users save the ones from evil and wicked OU:
#$goodUsersOU = $computers| ? {$_.DistinguishedName -notlike "*ou=Users, ou=Service Accounts,*" -and $_.DistinguishedName -notlike "*ou=Builtin,*"

# ############################################# 


# Document Group Memberships and export to CSV 

Get-ADUser -SearchBase $SearchBase -Filter {(LastLogonDate -like $xDays -and Enabled -eq "true") | ? {$_.DistinguishedName -notlike "*ou=Service Accounts,*" -and $_.DistinguishedName -notlike "*ou=Builtin,*"} -Properties DisplayName, MemberOf | % {
  New-Object PSObject -Property @{
	UserName = $_.DisplayName
	Groups = ($_.MemberOf | Get-ADGroup | Select -ExpandProperty Name) -join ","
	}}
} | Select UserName, Groups | Export-Csv C:\DeleteThisFile.csv -NTI


# Pull all inactive users older than $xDays from a specified OU
$Users = Get-ADUser -SearchBase $SearchBase -Properties memberof, PasswordNeverExpires, WhenCreated, PasswordLastSet, LastLogonDate -Filter {
    (LastLogonDate -notlike '*' -OR LastLogonDate -le $xDays)
    -AND (PasswordLastSet -le $xDays)
    -AND (Enabled -eq $True)
    -AND (PasswordNeverExpires -eq $false)
    -AND (WhenCreated -le $xDays)
} |  ForEach-Object {
    Set-ADUser $_ -AccountExpirationDate $expire -Description $userdesc -WhatIf
    Move-ADObject $_ -TargetPath $ParkingOU -WhatIf
    $_ | select Name, SamAccountName, PasswordExpired, PasswordNeverExpires, WhenCreated, PasswordLastSet, LastLogonDate, @{n='Groups';e={(($_.memberof | Get-ADGroup).Name) -join '; '}}
}

$Users | Where-Object {$_} | Export-Csv $LogFile -NoTypeInformation
 
#start $LogFile 
