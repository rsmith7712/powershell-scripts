<#
    .INFORMATION
    =========================================================
    Created By: user22
    Created On: 08/25/2017
    Organization: Domain, Inc.
    Filename: Check-ExchangeStatus.ps1
    =========================================================
    .DESCRIPTION
        Checks the exchange online plan status for each licensed user.

    .VERSION INFO
        v.1 - Initial script build
#>

# ----------------------------------------------------------------------------------------------
# Initializations

$domainuser = "pcadmin4@example.com"
$domainpass = ConvertTo-SecureString "<password>" -AsPlainText -Force
$DomainCred = New-Object System.Management.Automation.PSCredential $domainuser, $domainpass

#connects the powershell session to o365, requires o365 admin creds
Connect-MsolService -Credential $DomainCred

# ----------------------------------------------------------------------------------------------
# Logging
$stamp = Get-Date -Format MM.dd.yyyy-hh.mm.ss
$Script:Logfile = "C:\temp\Check-ExchangeStatus_$stamp.txt"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "User, License Status"
function Append-Log($message)
{
    $thetime = Get-Date -Format t
	Add-Content $Script:LogFile "$message"
}

# ----------------------------------------------------------------------------------------------
# Variables

#gets a list of active o365 users with disabled exchange plans.
$audit = Get-MsolUser -All | where {$_.isLicensed -eq $true -and $_.Licenses[0].ServiceStatus[15].ProvisioningStatus -eq "Disabled"}

#gets the UPNs of the users and compiles a list
$users = $audit.userprincipalname

#plans that are disabled.
$license = @()
$license += "INTUNE_O365"
$license += "RMS_S_ENTERPRISE"

$licenseoptions = New-MsolLicenseOptions -AccountSkuId domain:ENTERPRISEPACK -DisabledPlans $license

# ----------------------------------------------------------------------------------------------
# Script

foreach($user in $users)
{
    #removes and then re-assigns the license. This ensures that the correct plans are assigned.
    #Set-MsolUserLicense -UserPrincipalName $user -RemoveLicenses "domain:ENTERPRISEPACK"
    #Set-MsolUserLicense -UserPrincipalName $user -AddLicenses "domain:ENTERPRISEPACK" -LicenseOptions $licenseoptions

     Append-Log "$user, license re-applied with correct plan settings."
}