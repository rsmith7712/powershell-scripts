# Inactive_ADUserRpt_n_Move_v3.ps1
#
# Git- admin7712, 2016-05-20
# 
# Contributors:
# @Ericuser26, @AnthonyStringer, @DonJones 
# 
# Purpose of Script:
# 1. Query ADUsers in a specific OU and identify those that have been inactive for 90-days or more 
# 2. Document their Group Memberships 
# 3. Make a note in the user's Description field that the 'Account Disabled as of yyyy/mm/dd' 
# 4. Disable user's account 
# 5. Move the disabled user's account to a 'Parking' OU 
# 
# ############################################# 
# 
# Current Issues:
#
# 
# ############################################# 
# 

 
# Import Modules Needed
Import-Module ActiveDirectory
 
# Output results to CSV file
$LogFile = "C:\Inactive_ADUserRpt_n_Move_v3_USERS.csv"
 
# Today's Date
$today = get-date -uformat "%Y/%m/%d"
 
# Date to search by
$xDays = (get-date).AddDays(-90)
#$xDays = (get-date).AddDays(-120)
#$xDays = (get-date).AddDays(-365)
 
# Expiration date
$expire = (get-date).AddDays(-1)
 
# Date disabled description variable
$userDesc = "Disabled Inactive" + " - " + $today + " - " + "Moved From OU" + " - " + $SearchBase
 
# Sets the OU to do the base search for all user accounts, change as required
#$SearchBase = "OU=MIT, OU=Service Accounts, OU=Domain Services, DC=Domain, DC=com"
#$SearchBase = "OU=Laptop, OU=IS, OU=Corporate Computers, DC=Domain, DC=com"
$SearchBase = "OU=Remote Accounts, DC=Domain, DC=com"
#$SearchBase = "DC=Domain, DC=com"

 
# Sets the OU where accounts will be MOVED TO, change as required
$ParkingOU = "OU=30Days, OU=Disabled Accounts, OU=Domain Services, DC=Domain, DC=com"


# Document Group Memberships and export to CSV 
# -- This will generate a CSV for ALL users in OU regardless of account status

Get-ADUser -SearchBase $SearchBase -Filter {LastLogonDate -like $xDays -and Enabled -eq "true"} -Properties DisplayName, MemberOf | % {
  New-Object PSObject -Property @{
	UserName = $_.DisplayName
	Groups = ($_.MemberOf | Get-ADGroup | Select -ExpandProperty Name) -join ","
	}
} | Select UserName, Groups | Export-Csv C:\ADUser_GroupMembership_Rpt.csv -NTI


# Pull all inactive users older than 90-days from a specified OU
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
