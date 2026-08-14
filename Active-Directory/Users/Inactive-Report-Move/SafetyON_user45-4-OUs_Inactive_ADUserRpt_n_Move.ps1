# 4-OUs_Inactive_ADUserRpt_n_Move_v5.ps1
#
# Git- admin7712, 2016-05-20
# 
# Contributors:
# @Ericuser26, @AnthonyStringer, @DonJones, @DanPotter 
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
$LogFile = "C:\temp\Inactive_ADUserRpt_n_Move_v5_USERS.csv"
 
# Today's Date
$today = get-date -uformat "%Y/%m/%d"
 
# Date to search by
$xDays = (get-date).AddDays(-30)
#$xDays = (get-date).AddDays(-90)
 
# Expiration date
$expire = (get-date).AddDays(-1)
 
# Date disabled description variable
$userDesc = "Disabled Inactive" + " - " + $today + " - " + "Moved From OU" + " - " + $SearchBase
 
# Sets the OU to do the base search for all user accounts, change as required
# -- In ForEach loop

#*****************************************************************
#*****************************************************************
# Sets the OU where accounts will be MOVED TO, change as required

#--> Enable when BULK processing of ALL Target OU's
$ParkingOU = "OU=Disabled Accounts, OU=Domain Services, DC=Domain, DC=com"

#--> Enable when processing for CORPORATE Accounts
#$ParkingOU = "OU=from_CorporateAccounts, OU=30Days, OU=Disabled Accounts, OU=Domain Services, DC=Domain, DC=com"

#--> Enable when processing for STORE Accounts
#$ParkingOU = "OU=from_StoreAccounts, OU=30Days, OU=Disabled Accounts, OU=Domain Services, DC=Domain, DC=com"

#--> Enable when processing for REMOTE Accounts
#$ParkingOU = "OU=from_RemoteAccounts, OU=30Days, OU=Disabled Accounts, OU=Domain Services, DC=Domain, DC=com"

#--> Enable when processing for TEMP Accounts
#$ParkingOU = "OU=from_TempAccounts, OU=30Days, OU=Disabled Accounts, OU=Domain Services, DC=Domain, DC=com"

#*****************************************************************
#*****************************************************************

# Sets the Inclusion OU
#--> Enable this one for REPORTING ONLY
$OUs = @("corporate accounts", "remote accounts", "store accounts", "temp accounts, OU=domain services")
#$OUs = @("Executive Management, OU=Corporate Accounts")

#--> Enable to process against JUST Corporate Accounts 
#$OUs = @("corporate accounts")

#--> Enable to process against JUST Remote Accounts 
#$OUs = @("remote accounts")

#--> Enable to process against JUST Store Accounts 
#$OUs = @("store accounts")

#--> Enable to process against JUST Temp Accounts 
#$OUs = @("temp accounts, OU=domain services")

#*****************************************************************
#*****************************************************************

$Output = @()

ForEach($OU in $OUs){
    # Document Group Memberships and export to CSV
    $SearchBase = "OU="+$OU+", DC=Domain, DC=com"

    Get-ADUser -SearchBase $SearchBase -Filter {LastLogonDate -like $xDays -and Enabled -eq "true"} -Properties DisplayName, MemberOf | % {
      New-Object PSObject -Property @{
	    UserName = $_.DisplayName
	    Groups = ($_.MemberOf | Get-ADGroup | Select-Object -ExpandProperty Name) -join ","
	    }}
    Select-Object UserName, Groups | Export-Csv C:\temp\DeleteThisFile.csv -NTI


    # Pull all inactive users older than $xDays from a specified OU
    $Users = Get-ADUser -SearchBase $SearchBase -Properties memberof, PasswordNeverExpires, WhenCreated, PasswordLastSet, LastLogonDate -Filter {
        (LastLogonDate -notlike '*' -OR LastLogonDate -le $xDays)
        -AND (PasswordLastSet -le $xDays)
        -AND (Enabled -eq $True)
        -AND (PasswordNeverExpires -eq $false)
        -AND (WhenCreated -le $xDays)
    } |  
    
    ForEach-Object {
        Set-ADUser $_ -AccountExpirationDate $expire -Description $userdesc -WhatIf
        #Move-ADObject $_ -TargetPath $ParkingOU -WhatIf
        $_ | Select-Object Name, SamAccountName, PasswordExpired, PasswordNeverExpires, WhenCreated, PasswordLastSet, LastLogonDate, @{n='Groups';e={(($_.memberof | Get-ADGroup).Name) -join '; '}}
    }

    $OutPut += $Users
    }

$OutPut | Where-Object {$_} | Export-Csv $LogFile -NoTypeInformation
