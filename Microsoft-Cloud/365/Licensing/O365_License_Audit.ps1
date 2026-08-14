<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 06/22/2017
    Organization: Domain, Inc.
    Filename: O365_License_Audit.ps1
    =========================================================
    .DESCRIPTION
        Script runs as a scheduled task.  Grabs list of users from specified OU's and verifies that users are licensed.  Dumps a report and then emails to specified users.

    .VERSION INFO
        v1 - initial script buildout
#>

# ----------------------------------------------------------------------------------------------
# Initializations

#imports the AD PS module.  Duh.
Import-Module ActiveDirectory

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = get-date -Format s | foreach {$_ -replace ":", "."}
$Script:Logfile = "C:\temp\O365_License_Audit\$stamp.csv"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "User, User Status, License Status, Action Taken"
# Appends the log file
function Append-Log($message)
{
	Add-Content $Script:LogFile "$message"
}

# ----------------------------------------------------------------------------------------------
# Functions

function Check-License($user)
{
    #eror code values below
    #code = 0 (account enabled, license already applied, no action taken)
    #code = 11 (account enabled, license missing, license applied)
    #code = 111 (account disabled, license missing, no action taken)
    #code = 100 (account disabled, license applied, license revoked)

    #checks to see if user is enabled
    $enablecheck = (Get-ADUser $user -Properties *).enabled

    #gets the user principal name of the user
    $UPN = (Get-ADUser $user -Properties *).userprincipalname

    #gets license information for specified user.  Comments are my favorite thing.
    $licensecheck = (Get-MsolUser -UserPrincipalName $UPN).licenses.accountskuid
    
    #Builds an array of licenses that we hate/dont use.
    $license = @()
    $license += "INTUNE_O365"
    $license += "RMS_S_ENTERPRISE"
    
    #Variable used in set-msoluserlicense to disable certain plans.  What is the meaning of life?
    $licenseoptions = New-MsolLicenseOptions -AccountSkuId domain:ENTERPRISEPACK -DisabledPlans $license

    $returncode = $null
    
    #checks to see if user is enabled or not. 42.
    if($enablecheck -eq "True")
    {
        #if user is enabled, and license is applied, makes log entry.
        if($licensecheck -eq "domain:ENTERPRISEPACK")
        {
            $returncode = "0"
        }
        #otherwise, adds license to user account. #winning
        else
        {
            Set-MsolUser -UserPrincipalName $UPN -UsageLocation "US"
			Set-MsolUserLicense -UserPrincipalName $UPN -AddLicenses "domain:ENTERPRISEPACK" -LicenseOptions $licenseoptions
            $returncode = "11"
        }
    }
    else 
    {
        #if user isnt enabled, checks for license.  If license exists, removes it. WOAH!
        if($licensecheck -eq "domain:ENTERPRISEPACK")
        {
            Set-MsolUserLicense -UserPrincipalName $UPN -RemoveLicenses domain:ENTERPRISEPACK
            $returncode = "100"
        }
        #comment? comment.
        else 
        {
            $returncode = "111"
        }
    }
    return $returncode
}

# ----------------------------------------------------------------------------------------------
# Variables

# Service account variables for o365 administration
$user = "o365useradmin@example.com"
$pass = Get-Content "\\SERVER\SHARE\...\o365useradmin.txt" | ConvertTo-SecureString
$creds = New-Object -TypeName system.management.automation.pscredential -ArgumentList $user, $pass

#pulls user list from AD, will add more OUs as needed.
$users = (Get-ADUser -Filter * -SearchBase "ou=corporate accounts,dc=domain,dc=com" -Properties *).samaccountname

# ----------------------------------------------------------------------------------------------
# Script

Connect-MsolService -Credential $creds

foreach($user in $users)
{
    $licenseStatus = Check-License $user
    <#
    License-Check $user
    if($returncode -eq "0")
    {
        Append-Log "$user, Enabled, Licensed"
    }
    elseif($returncode -eq "11")
    {
        Append-Log "$user, Enabled, Unlicensed, License Applied"
    }
    elseif($returncode -eq "100")
    {
        Append-Log "$user, Disabled, Licensed, Licensed Revoked"
    }
    elseif($returncode -eq "111")
    {
        Append-Log "$user, Disabled, Unlicensed"
    }
    #>
    switch ($licenseStatus) 
    { 
        0   { Append-Log ($user + ", Enabled, Licensed") } 
		11  { Append-Log ($user + ", Enabled, Unlicensed, License Applied") }
		100 { Append-Log ($user + ", Disabled, Licensed, Licensed Revoked") }
		111 { Append-Log ($user + ", Disabled, Unlicensed") }
		default { Append-Log "Unknown user status. Plus, Alex is a weeny." }
    }
}