<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 11/10/2017
    Organization: Domain, Inc.
    Filename: Terminate-UserAccount.ps1
    =========================================================
    .DESCRIPTION
        This script is used to terminate a specified user account.
        This script disables the account, backs up group memberships and revokes office license.

    .VERSION INFO
        v1.0 - Initial script build.
#>

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = get-date -Format s | foreach {$_ -replace ":", "."}
$Script:Logfile = "C:\temp\Terminate-UserAccount_$stamp.txt"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "Beginning account termination for $useralias"
function Append-Log($message)
{
    $thetime = Get-Date -Format t
	Add-Content $Script:LogFile "$thetime -- $message"
}

# ----------------------------------------------------------------------------------------------
# Initializations

Import-Module -Name ActiveDirectory

#Gets users admin credentials
$cred = Get-Credential

#below is used to verify authentication
$username = $cred.username
$password = $cred.GetNetworkCredential().password

# Get current domain using logged-on user's credentials
$CurrentDomain = "LDAP://" + ([ADSI]"").distinguishedName
$domain = New-Object System.DirectoryServices.DirectoryEntry($CurrentDomain,$UserName,$Password)

#checks to make sure admin creds are valid
if ($domain.name -eq $null)
{
write-host "Authentication failed - please verify your username and password." -ForegroundColor Red
exit #terminate the script.
}
else
{
write-host "Successfully authenticated with domain $domain.name" -ForegroundColor Yellow
}

# ----------------------------------------------------------------------------------------------
# Functions

function check-msonline
{
	$check = (Get-Module -ListAvailable -name msonline).Name
	if ($check -eq "MSOnline")
	{
	}
	else
	{
		if (!(test-path C:\software))
		{
			New-Item -Path C:\Software -ItemType Directory
			Copy-Item -path "\\SERVER\SHARE\...\Desktop Software\Powershell\msonline\msoidcli_64.msi" -Destination C:\Software\msoidcli_64.msi -Force
			Copy-Item -path "\\SERVER\SHARE\...\Desktop Software\Powershell\msonline\AdministrationConfig-en.msi" -destination C:\Software\Administrationconfig-en.msi -Force
			Start-Process msiexec.exe -ArgumentList "/i C:\software\msoidcli_64.msi /qn" -wait
			Start-Process msiexec.exe -ArgumentList "/i C:\software\Administrationconfig-en.msi /qn" -wait
		}
		else
		{
			Copy-Item -path "\\SERVER\SHARE\...\Desktop Software\Powershell\msonline\msoidcli_64.msi" -Destination C:\Software\msoidcli_64.msi -Force
			Copy-Item -path "\\SERVER\SHARE\...\Desktop Software\Powershell\msonline\AdministrationConfig-en.msi" -destination C:\Software\Administrationconfig-en.msi -Force
			Start-Process msiexec.exe -ArgumentList "/i C:\software\msoidcli_64.msi /qn" -wait
			Start-Process msiexec.exe -ArgumentList "/i C:\software\Administrationconfig-en.msi /qn" -wait
		}
	}
}

function disable_account ($cred)
{
    Disable-ADAccount -Server "srv" -Identity $script:useralias -Credential $cred
}

function backup_adgroup ($cred) 
{
    $stamp = get-date -Format MM.dd.yyyy
    $filename = $script:useralias + "_" + $stamp
    $groups = @()
    $groups += (Get-ADPrincipalGroupMembership -Identity $script:useralias -Credential $cred).name
    $groups | Out-File -FilePath "\\SERVER\SHARE\...\Disabled AD UserGroup Membership\$filename.txt" -Force
}

function revoke_license ($cred) 
{
    $upn = $script:useralias + "@example.com"
    Connect-MsolService -Credential $cred
    #check to see if user is licensed. If licensed, removes each existing license.
    $licensecheck = (Get-MsolUser -UserPrincipalName $upn).licenses.accountskuid
    if($licensecheck -ne $null)
    {
        foreach($license in $licensecheck)
        {
            Set-MsolUserLicense -UserPrincipalName $upn -RemoveLicenses $license
            Write-Host "$license license revoked"
            Append-Log "$license license revoked"
        }
    }
    else 
    {
        Write-Host "$script:useralias has no existing licenses"
        Append-Log "$script:useralias has no existing licenses"
    }
}

function remove_adgroup ($cred)
{
    $groups = (get-aduser -Identity $script:useralias -Properties MemberOf).MemberOf

    foreach ($group in $groups)
    {
        Remove-ADGroupMember -Identity $group -Members $script:useralias -Confirm:$false | Out-Null
        if($? -eq $false)
        {
            Write-Host "Group removal failed for $group"
            Append-Log "Group removal failed for $group"
        }
        else 
        {
            Write-Host "$script:useralias has been removed from $group"
            Append-Log "$script:useralias has been removed from $group"
        }

    }
}

function disabled_OU ($cred)
{
    $dn = (get-aduser -Identity $script:useralias).distinguishedName
    Move-ADObject -Identity $dn -TargetPath "OU=Disabled Accounts,OU=Domain Services,DC=Domain,DC=com" -Credential $cred -Server "srv"
    if($? -eq $false)
    {
        Write-Host "Unable to move $script:useralias to Disabled Accounts OU"
        Append-Log "Unable to move $script:useralias to Disabled Accounts OU"
    }
    else
    {
        Write-Host "$script:useralias moved to Disabled Users OU"
        Append-Log "$script:useralias moved to Disabled Users OU"
    }
}

# ----------------------------------------------------------------------------------------------
# Variables

#gets $script:useralias variable and checks to make sure user exists.
do
{
    if ($count -ge 1)
    {
        Write-Host "Unable to find user in AD. Try Again" -ForegroundColor Red
    }
    $script:useralias = Read-Host "Please enter the user whom you would like to terminate"
    $usertest = dsquery user -samid $script:useralias
    if ($usertest -eq $null) { $test = $false }
    else { $test = $true }
    $count++
}
while ($test -ne $true)

# ----------------------------------------------------------------------------------------------
# Script

#verifies that msonline module is installed and installs if not. Then import the module.  This is used later for revoking office 365 license.
check-msonline

Import-Module -Name MSOnline

#disables account and does basic error checking
disable_account $cred
start-sleep -Seconds 5
$enablecheck = (Get-ADUser -Server "srv" -Identity $script:useralias).enabled
if($enablecheck -eq $false)
{
    Write-host "$script:useralias account disabled succesfully."
    Append-Log "$script:useralias account disabled succesfully."
}
else
{
    Write-Host "Unable to disable account, exiting script."
    Append-Log "Unable to disabled account, exiting script."
    exit
}

#backup group membership
backup_adgroup $cred

#removes group memberships
remove_adgroup $cred

#moves account to disabled OU
disabled_OU $cred

#backup mailbox
#impossible with exchange online.  This needs to be a manual task.

#revoke office license
revoke_license $cred