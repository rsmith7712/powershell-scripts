# help_ZombieAcct_90dayRpt_n_Move.ps1
#
# Git- admin7712, 2016-05-20
# 
# Purpose of Script:
# 1. (Initially) Query ADUsers in a specific OU and identify those that have been inactive for 90-days or more 
# 2. Document their Group Memberships 
# 3. Make a note in the user's Description field that the 'Account Disabled as of yyyy/mm/dd' 
# 4. Disable user's account 
# 5. Move the disabled user's account to a 'Parking' OU 
# 
# ############################################# 
# 
# Current Issues:
# 1. Unable to add in the functionality of querying and adding the results of Get-ADGroup and memberof to original query 
# 2. Making the comment in the Description field 
# 3. Moving the ADObject to specified OU 
# 
# ############################################# 
# 


# Import Modules Needed
Import-Module ActiveDirectory

# Output results to CSV file, and define row headers
$Script:LogFile = "C:\help_ZombieAcct_90dayRpt_n_Move.csv"
If(!(Test-Path $Script:LogFile)){
	New-Item $Script:LogFile -type "File"
	}

Add-Content -Path $Script:LogFile -Value "Name, User Account,Pswd Exp, Pswd Nvr Exp, When Created,Password Last Set, Last Logon Date, Group Memberships"

# Today's Date
$today = get-date -uformat "%Y/%m/%d"

# Date to search by
$xDays = (get-date).AddDays(-90)

# Expiration date
$expire = (get-date).AddDays(-1)

# Date disabled description variable
$userDesc = "Disabled Inactive" + " - " + $today

# Sets the OU to do the base search for all user accounts, change as required
$SearchBase = "OU=MIT, OU=Service Accounts, OU=Domain Services, DC=Domain, DC=com"

# Sets the OU where accounts will be MOVED TO, change as required
$ParkingOU = "OU=30Days, OU=Disabled Accounts, OU=Domain Services, DC=Domain, DC=com"

# Pull all inactive users older than 90-days from a specified OU
$Users = Get-ADUser -SearchBase $SearchBase -Properties memberof, * -Filter {(LastLogonDate -notlike "*" -OR LastLogonDate -le $xDays) 
    -AND (PasswordLastSet -le $xDays) 
    -AND (Enabled -eq $True)
    -AND (PasswordNeverExpires -eq $false) 
    -AND (WhenCreated -le $xDays)}
    
    # Queries for Group Memberhips 
    New-Object PSObject -Property @{
	UserName = $_.DisplayName
	Groups = ($_.memberof | Get-ADGroup | Select -ExpandProperty Name) -join ","
	}
    
    select-object Name, SAMaccountName, PasswordExpired, PasswordNeverExpires, WhenCreated, PasswordLastSet, LastLogonDate, Groups

foreach ($User in $Users){
    $csvout1 = $User.Name
    $csvout2 = $User.SamAccountName
    $csvout3 = $User.PasswordExpired
    $csvout4 = $User.PasswordNeverExpires
    $csvout5 = $User.WhenCreated
    $csvout6 = $User.PasswordLastSet
    $csvout7 = $User.LastLogonDate
    $csvout8 = $User.Groups
    #Set-ADUser $User -AccountExpirationDate $expire -Description $userdesc
    #Get-ADUser $User | Move-ADObject -targetpath $ParkingOU
    Add-Content -Path $Script:LogFile -Value "$csvout1,$csvout2,$csvout3,$csvout4,$csvout5,$csvout6,$csvout7"
    }