<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: XX/XX/XXXX
    Organization: Domain, Inc.
    Filename: Remote_Accounts_Check.ps1
    =========================================================
    .DESCRIPTION
        [ENTER A BRIEF DESCRIPTION OF SCRIPT AND ITS PURPOSE]

    .VERSION INFO
        [ENTER ANY CHANGES MADE HERE]
#>

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = get-date -Format s | foreach {$_ -replace ":", "."}
$Script:Logfile = "C:\temp\Remote_accounts_$stamp.csv"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "User, OU, License Status"
function Append-Log($message)
{
    $thetime = Get-Date -Format t
	Add-Content $Script:LogFile "$message"
}

# ----------------------------------------------------------------------------------------------
# Functions

# ----------------------------------------------------------------------------------------------
# Variables

$directors = (Get-ADUser -Filter * -SearchBase "ou=directors,ou=remote accounts,dc=domain,dc=com").userprincipalname
$DM = (Get-ADUser -Filter * -SearchBase "ou=district managers,ou=remote accounts,dc=domain,dc=com").userprincipalname
$HR = (Get-ADUser -Filter * -SearchBase "ou=Human Resources,ou=remote accounts,dc=domain,dc=com").userprincipalname
$inventory = (Get-ADUser -Filter * -SearchBase "ou=inventory management and logistics,ou=remote accounts,dc=domain,dc=com").userprincipalname
$LP = (Get-ADUser -Filter * -SearchBase "ou=Loss Prevention,ou=remote accounts,dc=domain,dc=com").userprincipalname
$Marketing = (Get-ADUser -Filter * -SearchBase "ou=Marketing,ou=remote accounts,dc=domain,dc=com").userprincipalname
$RealEstate = (Get-ADUser -Filter * -SearchBase "ou=real estate and development,ou=remote accounts,dc=domain,dc=com").userprincipalname
$recycling = (Get-ADUser -Filter * -SearchBase "ou=recycling,ou=remote accounts,dc=domain,dc=com").userprincipalname
$RM = (Get-ADUser -Filter * -SearchBase "ou=Regional Managers,ou=remote accounts,dc=domain,dc=com").userprincipalname
$sourcing = (Get-ADUser -Filter * -SearchBase "ou=sourcing,ou=remote accounts,dc=domain,dc=com").userprincipalname

# ----------------------------------------------------------------------------------------------
# Script

Connect-MsolService

foreach($user in $directors){
    $check = (Get-MsolUser -UserPrincipalName $user).licenses.accountskuid
    if($check -eq "domain:ENTERPRISEPACK"){
        append-log "$user, Directors, Licensed"
    }
    else {
        append-log "$user, Directors, Not Licensed"
    }
}

foreach($user in $DM){
    $check = (Get-MsolUser -UserPrincipalName $user).licenses.accountskuid
    if($check -eq "domain:ENTERPRISEPACK"){
        append-log "$user, District Managers, Licensed"
    }
    else {
        append-log "$user, District Managers, Not Licensed"
    }
}

foreach($user in $HR){
    $check = (Get-MsolUser -UserPrincipalName $user).licenses.accountskuid
    if($check -eq "domain:ENTERPRISEPACK"){
        append-log "$user, Human Resources, Licensed"
    }
    else {
        append-log "$user, Human Resources, Not Licensed"
    }
}

foreach($user in $inventory){
    $check = (Get-MsolUser -UserPrincipalName $user).licenses.accountskuid
    if($check -eq "domain:ENTERPRISEPACK"){
        append-log "$user, inventory management, Licensed"
    }
    else {
        append-log "$user, inventory management, Not Licensed"
    }
}

foreach($user in $LP){
    $check = (Get-MsolUser -UserPrincipalName $user).licenses.accountskuid
    if($check -eq "domain:ENTERPRISEPACK"){
        append-log "$user, Loss Prevention, Licensed"
    }
    else {
        append-log "$user, Loss Prevention, Not Licensed"
    }
}

foreach($user in $Marketing){
    $check = (Get-MsolUser -UserPrincipalName $user).licenses.accountskuid
    if($check -eq "domain:ENTERPRISEPACK"){
        append-log "$user, Marketing, Licensed"
    }
    else {
        append-log "$user, Marketing, Not Licensed"
    }
}

foreach($user in $RealEstate){
    $check = (Get-MsolUser -UserPrincipalName $user).licenses.accountskuid
    if($check -eq "domain:ENTERPRISEPACK"){
        append-log "$user, Real Estate, Licensed"
    }
    else {
        append-log "$user, Real Estate, Not Licensed"
    }
}

foreach($user in $recycling){
    $check = (Get-MsolUser -UserPrincipalName $user).licenses.accountskuid
    if($check -eq "domain:ENTERPRISEPACK"){
        append-log "$user, Recycling, Licensed"
    }
    else {
        append-log "$user, Recycling, Not Licensed"
    }
}

foreach($user in $RM){
    $check = (Get-MsolUser -UserPrincipalName $user).licenses.accountskuid
    if($check -eq "domain:ENTERPRISEPACK"){
        append-log "$user, Regional Managers, Licensed"
    }
    else {
        append-log "$user, Regional Managers, Not Licensed"
    }
}

foreach($user in $sourcing){
    $check = (Get-MsolUser -UserPrincipalName $user).licenses.accountskuid
    if($check -eq "domain:ENTERPRISEPACK"){
        append-log "$user, Sourcing, Licensed"
    }
    else {
        append-log "$user, Sourcing, Not Licensed"
    }
}