# Get-InactiveUser.ps1
#
# 90 day inactive user report pulling from Active Directory
# Pirate 2016-05-20
#

##################################################
##												##
## Query1 - Create report pulling info on		## 
##			Active Directory User Accounts		##
##			inactive longer than 90-days		##
##												##
##################################################

# Import Modules Needed
Import-Module ActiveDirectory

# Today's Date
$today = get-date -uformat "%Y/%m/%d"

# Date to search by
#$xDays = (get-date).AddDays(-90)
$xDays = (get-date).AddDays(-120)

# Expiration date
$expire = (get-date).AddDays(-1)

# Date disabled description variable
#$userDesc = "Disabled Inactive" + " - " + $today

# Sets the OU to do the base search for all user accounts, change as required
#$SearchBase = "OU=MIT,OU=Service Accounts,OU=Domain Services,DC=Domain,DC=com"
$SearchBase = "DC=Domain,DC=com"

# Sets the OU where accounts will be moved, change as required
$ParkingOU = "OU=30Days, OU=Disabled Accounts, OU=Domain Services, DC=Domain, DC=com"

# Define user search query 
$users | Foreach-object {Get-ADUser -searchbase $SearchBase -Properties * -Filter {(LastLogonDate -notlike "*" -OR LastLogonDate -le $xDays) 
    -AND (PasswordLastSet -le $xDays) 
    -AND (enabled -eq $True) 
    -AND (PasswordNeverExpires -eq $false) 
    -AND (WhenCreated -le $xDays)}} | 
select-object Name, SAMaccountName, PasswordExpired, PasswordNeverExpires, WhenCreated, PasswordLastSet, LastLogonDate | 

# Export results to CSV
export-csv c:\Get-InactiveUser_USERS.csv


##################################################
##												##
## Query2 - Create report pulling info on		## 
##			Active Directory User Accounts		##
##			and their Group Memberships 		##
##												##
##################################################

Get-ADUser -Filter * -Properties DisplayName,memberof -searchbase $SearchBase | % {
  New-Object PSObject -Property @{
	UserName = $_.DisplayName
	Groups = ($_.memberof | Get-ADGroup | Select -ExpandProperty Name) -join ","
	}
} | Select UserName,Groups | Export-Csv C:\Get-InactiveUser_GROUPS.csv -NTI


