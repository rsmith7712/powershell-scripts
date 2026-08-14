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
    PCI_Auditor_Requested_DC_Info.ps1

.DESCRIPTION
    Produces PCI-audit information on domain user accounts: reports users inactive 90+ days, documents their group memberships, and annotates, disables and relocates the accounts.

.FUNCTIONALITY
    Reports and remediates inactive AD accounts for PCI audit.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# PCI_Auditor_Requested_DC_Info.ps1
# 
# Contributors:
# @Richard Smith 
# 
# Purpose of Script:
# 1. Query ADUsers in a specific OU and identify those that have been inactive for 90-days or more 
#    --> If run at a Domain level, script can Exclude specific OU's
# 2. Document their Group Memberships 
# 3. Make a note in the user's Description field that the 'Account Disabled as of yyyy/mm/dd' 
# 4. Make a note in the user's Description field of the OU they were resident in
# 5. Disable user's account 
# 6. Move the disabled user's account to a 'ParkingOU' 
# 7. Generate a report and export results to a .CSV file 
# 
# ############################################# 
# 
# Current Issues:
# 1. 
# 
# ############################################# 
# 
 
# Import Modules Needed
Import-Module ActiveDirectory
 
# Output results to CSV file
$LogFile = "C:\PCI_Auditor_Requested_DC_Information.csv"
 
# Today's Date
$today = get-date -uformat "%Y/%m/%d"
 
# Date to search by
$xDays = (get-date).AddDays(-30)
#$xDays = (get-date).AddDays(-90)
 
# Expiration date
$expire = (get-date).AddDays(-1)
 
# Date disabled description variable
$userDesc = "Disabled Inactive" + " - " + $today + " - " + "Moved From OU" + " - " + $SearchBase

#*****************************************************************
#*****************************************************************

# Sets the Inclusion OU
#--> Enable this one for REPORTING ONLY
$OUs = @("domain servers")

#*****************************************************************
#*****************************************************************

$Output = @()

ForEach($OU in $OUs){
    # Document Group Memberships and export to CSV
    $SearchBase = "OU="+$OU+", DC=Domain, DC=com"

    Get-ADUser -SearchBase $SearchBase -Filter {LastLogonDate -like $xDays -and Enabled -eq "true"} -Properties DisplayName, MemberOf | % {
      New-Object PSObject -Property @{
	    UserName = $_.DisplayName
	    Groups = ($_.MemberOf | Get-ADGroup | Select -ExpandProperty Name) -join ","
	    }}
    Select UserName, Groups | Export-Csv C:\DeleteThisFile.csv -NTI


    # Pull all inactive users older than $xDays from a specified OU
    $Users = Get-HotFix -SearchBase $SearchBase -Properties memberof, PasswordNeverExpires, WhenCreated, PasswordLastSet, LastLogonDate -Filter {
        (LastLogonDate -notlike '*' -OR LastLogonDate -le $xDays)
        -AND (PasswordLastSet -le $xDays)
        -AND (Enabled -eq $True)
        -AND (PasswordNeverExpires -eq $false)
        -AND (WhenCreated -le $xDays)
    } |  
    
    ForEach-Object {
        Set-ADUser $_ -AccountExpirationDate $expire -Description $userdesc -WhatIf
        Move-ADObject $_ -TargetPath $ParkingOU -WhatIf
        $_ | select Name, SamAccountName, PasswordExpired, PasswordNeverExpires, WhenCreated, PasswordLastSet, LastLogonDate, @{n='Groups';e={(($_.memberof | Get-ADGroup).Name) -join '; '}}
    }

    $OutPut += $Users
    }

$OutPut | Where-Object {$_} | Export-Csv $LogFile -NoTypeInformation
