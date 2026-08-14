<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: XX/XX/XXXX
    Organization: Domain, Inc.
    Filename: fixstrlicensing.ps1
    Description: [ENTER A BRIEF DESCRIPTION OF SCRIPT AND ITS PURPOSE]
    =========================================================
    .VERSION
        [ENTER CURRENT VERSION INFO]

    .VERSION INFO
        [ENTER PREVIOUS VERSION INFO]
#>

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = Get-Date -Format "HHmmss"
$Script:Logfile = "C:\temp\strLicense_$stamp.txt"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "Account, Status"
function Append-Log($message)
{
	Add-Content $Script:LogFile "$message"
}
# ----------------------------------------------------------------------------------------------
#Variables

$fullusers = Get-ADUser -Filter * -SearchBase "ou=store users,ou=store accounts,dc=domain,dc=com"

$users = @()

$upn = @()

$license = @()
$license += "INTUNE_O365"
$license += "RMS_S_ENTERPRISE"
$license += "TEAMS1"

$licenseoptions = New-MsolLicenseOptions -AccountSkuId domain:ENTERPRISEPACK -DisabledPlans $license

# ----------------------------------------------------------------------------------------------
#Script

Connect-MsolService

foreach($user in $fullusers)
{
    if($user.name -like "*lab*")
    {
        Append-Log "$user.name, Lab Account"
    }
    else
    {
        $users += $user.samaccountname
    }
}


foreach($user in $users){$upn += $user+"@example.com"}

foreach($user in $upn) 
{
    if ($user.substring(0,1) -eq "1")
    {
        if((get-msoluser -UserPrincipalName $user).licenses.accountskuid -eq "domain:ENTERPRISEPACK")
        {
            Append-Log "$user, already licensed"
        }
        else
        {
            Set-MsolUser -UserPrincipalName $user -UsageLocation "US"
            Set-MsolUserLicense -UserPrincipalName $user -AddLicenses domain:ENTERPRISEPACK -LicenseOptions $licenseoptions
            if($? -eq $False)
            {
                Append-Log "$user, Failed"
            }
            Else
            {
                Append-Log "$user, License Applied"
            }
        }
    }
    if ($user.substring(0,1) -eq "2")
    {
        if((get-msoluser -UserPrincipalName $user).licenses.accountskuid -eq "domain:ENTERPRISEPACK")
        {
            Append-Log "$user, already licensed"
        }
        else
        {
            Set-MsolUser -UserPrincipalName $user -UsageLocation "CA"
            Set-MsolUserLicense -UserPrincipalName $user -AddLicenses domain:ENTERPRISEPACK -LicenseOptions $licenseoptions
            if($? -eq $False)
            {
                Append-Log "$user, Failed"
            }
            Else
            {
                Append-Log "$user, License Applied"
            }
        }
    }
    if ($user.substring(0,1) -eq "3")
    {
        if((get-msoluser -UserPrincipalName $user).licenses.accountskuid -eq "domain:ENTERPRISEPACK")
        {
            Append-Log "$user, already licensed"
        }
        else
        {
            Set-MsolUser -UserPrincipalName $user -UsageLocation "AU"
            Set-MsolUserLicense -UserPrincipalName $user -AddLicenses domain:ENTERPRISEPACK -LicenseOptions $licenseoptions
            if($? -eq $False)
            {
                Append-Log "$user, Failed"
            }
            Else
            {
                Append-Log "$user, License Applied"
            }
        }
    }
    if ($user.substring(0,1) -eq "5")
    {
        if((get-msoluser -UserPrincipalName $user).licenses.accountskuid -eq "domain:ENTERPRISEPACK")
        {
            Append-Log "$user, already licensed"
        }
        else
        {
            Set-MsolUser -UserPrincipalName $user -UsageLocation "US"
            Set-MsolUserLicense -UserPrincipalName $user -AddLicenses domain:ENTERPRISEPACK -LicenseOptions $licenseoptions
            if($? -eq $False)
            {
                Append-Log "$user, Failed"
            }
            Else
            {
                Append-Log "$user, License Applied"
            }
        }
    }
    if ($user.substring(0,1) -eq "8")
    {
        if((get-msoluser -UserPrincipalName $user).licenses.accountskuid -eq "domain:ENTERPRISEPACK")
        {
            Append-Log "$user, already licensed"
        }
        else
        {
            Set-MsolUser -UserPrincipalName $user -UsageLocation "US"
            Set-MsolUserLicense -UserPrincipalName $user -AddLicenses domain:ENTERPRISEPACK -LicenseOptions $licenseoptions
            if($? -eq $False)
            {
                Append-Log "$user, Failed"
            }
            Else
            {
                Append-Log "$user, License Applied"
            }
        }
    }
}