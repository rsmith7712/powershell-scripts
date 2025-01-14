# LEGAL
<# LICENSE
    MIT License, Copyright 2016 Richard Smith

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
.NAME
   AD-DomainOuDialInSettingModification.ps1

.SYNOPSIS
		# 1. Query ADUsers in a specific OU  
		# 2. Set the Network Access Permissions to 'Control access through NPS Network Policy' under the Dial-in tab
		# 3. Make a note in the user's Description field that the 'Dial-in settings changed as of yyyy/mm/dd' 
		# 4. Export results to a .CSV file of accounts affected

.FUNCTIONALITY

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts - AD-Domain OU Dial In Setting Modification
#>

# Import Modules Needed
Import-Module ActiveDirectory

# Output results to CSV file
$LogFile = "C:\OU_Acts_Modified.csv"

# Today's Date
$today = get-date -uformat "%Y/%m/%d"

# Date to search by
$xDays = (get-date).AddDays(-1)

# Date disabled description variable
$userDesc = "Dial-in Settings Updated on:" + " - " + $today 

# Sets the OU to do the base search for all user accounts, change as required
#$SearchBase = "OU=Ticket, OU=Service Accounts, OU=Domain Services, DC=DOMAIN, DC=com"
$SearchBase = "OU=Laptop, OU=IS, OU=Corporate Computers, DC=DOMAIN, DC=com"

# Pull all inactive users older than $xDays from a specified OU
$Users = Get-ADUser -SearchBase $SearchBase -Properties PasswordNeverExpires, LastLogonDate -Filter {
    (LastLogonDate -le $xDays)
    -AND (Enabled -eq $True)
} |  ForEach-Object {
    # To set Dial-in = DENY
    #Set-ADUser $_ -Replace @{msNPAllowDialIn=$FALSE} -WhatIf 
    
    # To set Dial-in = Control Access Through NPS Network Policy
    Set-ADUser $_ -Clear msNPAllowDialIn;
   
    #Set-ADUser $_ -AccountExpirationDate $today -Description $userdesc 
    $_ | select Name, SamAccountName, PasswordNeverExpires, LastLogonDate
}

$Users | Where-Object {$_} | Export-Csv $LogFile -NoTypeInformation 
 
#start $LogFile 