<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 06/21/2017
    Organization: Domain, Inc.
    Filename: AD_User_query_6160452.ps1
    =========================================================
    .DESCRIPTION
        Query's AD for a list of email addresses, 

    .VERSION INFO
        [ENTER ANY CHANGES MADE HERE]
#>

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = get-date -Format s | foreach {$_ -replace ":", "."}
$Script:Logfile = "C:\temp\AD_User_Query_$stamp.csv"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "Name, Description, Email Address, Logon Name"
function Append-Log($message)
{
	Add-Content $Script:LogFile "$message"
}

# ----------------------------------------------------------------------------------------------
# Variables

$users = @()
$users += (Get-ADUser -Filter * -SearchBase "ou=corporate accounts,dc=domain,dc=com").samaccountname
$users += (Get-ADUser -Filter * -SearchBase "ou=partner accounts,dc=domain,dc=com").samaccountname
$users += (Get-ADUser -Filter * -SearchBase "ou=remote accounts,dc=domain,dc=com").samaccountname

# ----------------------------------------------------------------------------------------------
# Script

foreach($user in $users){
    $name = (Get-ADUser $user -Properties *).name
    $description = (Get-ADUser $user -Properties *).description
    $email = (Get-ADUser $user -Properties *).userprincipalname
    Append-Log "$name, $description, $email, $user"
}