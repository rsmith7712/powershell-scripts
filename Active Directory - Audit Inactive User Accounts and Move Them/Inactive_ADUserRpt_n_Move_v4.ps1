<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.129
	 Created on:   	5/20/2016 10:41 AM
	 Created by:   	RSmith7712, @EricRocconi, @AnthonyStringer, @DonJones, @DanPotter
	 Organization: 	
	 Filename:     	Inactive_ADUserRpt_n_Move_v4.ps1
	===========================================================================
	.DESCRIPTION
		# Purpose of Script:
			# 1. Query ADUsers in a specific OU and identify those that have been inactive for 90-days or more 
			# 2. Document their Group Memberships 
			# 3. Make a note in the user's Description field that the 'Account Disabled as of yyyy/mm/dd' 
			# 4. Make a note in the user's Description field of the OU they were resident in
			# 5. Disable user's account 
			# 6. Move the disabled user's account to a 'ParkingOU' 
			# 7. Generate a report and export results to a .CSV file 
#>

# Import Modules Needed
Import-Module ActiveDirectory
 
# Output results to CSV file
$LogFile = "C:\Domain_Inactive_ADUserRpt_n_Move_v4_USERS.csv"
 
# Today's Date
$today = get-date -uformat "%Y/%m/%d"
 
# Date to search by
$xDays = (get-date).AddDays(-90)
 
# Expiration date
$expire = (get-date).AddDays(-1)
 
# Date disabled description variable
$userDesc = "Disabled Inactive" + " - " + $today + " - " + "Moved From OU" + " - " + $SearchBase
 
# Sets the OU to do the base search for all user accounts, change as required
$SearchBase = "DC=DOMAIN, DC=com"

# Sets the OU where accounts will be MOVED TO, change as required
$ParkingOU = "OU=30Days, OU=Disabled Accounts, OU=Domain Services, DC=DOMAIN, DC=com"

# Document Group Memberships and export to CSV 

Get-ADUser -SearchBase $SearchBase -Filter {LastLogonDate -like $xDays -and Enabled -eq "true"} -Properties DisplayName, MemberOf | % {
  New-Object PSObject -Property @{
	UserName = $_.DisplayName
	Groups = ($_.MemberOf | Get-ADGroup | Select -ExpandProperty Name) -join ","
	}}
Select UserName, Groups | Export-Csv C:\DeleteThisFile.csv -NTI

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