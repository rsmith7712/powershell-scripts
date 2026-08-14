# LEGAL
<# LICENSE
    MIT License, Copyright 2017 Richard Smith

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    IN THE SOFTWARE.
#>
# GENERAL SCRIPT INFORMATION
<#
.NAME
    o365-masslicense.ps1

.DESCRIPTION
    Assigns Microsoft 365 licenses in bulk to users gathered from corporate, partner and remote account OUs.

.FUNCTIONALITY
    Bulk-assigns Microsoft 365 licenses.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$userlist = @()

<#
#corporate accounts
$userlist += Get-ADUser -Filter * -SearchBase "OU=corporate accounts, DC=domain, DC=com" | select -Property userprincipalname

#partner accounts
$userlist += Get-ADUser -Filter * -SearchBase "OU=domain retail, OU=partner accounts, DC=domain, DC=com" | select -Property userprincipalname
$userlist += Get-ADUser -Filter * -SearchBase "OU=partner1, OU=partner accounts, DC=domain, DC=com" | select -Property userprincipalname
$userlist += Get-ADUser -Filter * -SearchBase "OU=partner2, OU=partner accounts, DC=domain, DC=com" | select -Property userprincipalname
$userlist += Get-ADUser -Filter * -SearchBase "OU=partner3, OU=partner accounts, DC=domain, DC=com" | select -Property userprincipalname

#remote accounts
$userlist += Get-ADUser -Filter * -SearchBase "OU=ads leads, OU=remote accounts, DC=domain, DC=com" | select -Property userprincipalname
$userlist += Get-ADUser -Filter * -SearchBase "OU=ads management, OU=remote accounts, DC=domain, DC=com" | select -Property userprincipalname
$userlist += Get-ADUser -Filter * -SearchBase "OU=directors, OU=remote accounts, DC=domain, DC=com" | select -Property userprincipalname
$userlist += Get-ADUser -Filter * -SearchBase "OU=District Managers, OU=remote accounts, DC=domain, DC=com" | select -Property userprincipalname
$userlist += Get-ADUser -Filter * -SearchBase "OU=Human Resources, OU=remote accounts, DC=domain, DC=com" | select -Property userprincipalname
$userlist += Get-ADUser -Filter * -SearchBase "OU=Inventory Management and Logistics, OU=remote accounts, DC=domain, DC=com" | select -Property userprincipalname
$userlist += Get-ADUser -Filter * -SearchBase "OU=Loss Prevention, OU=remote accounts, DC=domain, DC=com" | select -Property userprincipalname
$userlist += Get-ADUser -Filter * -SearchBase "OU=Marketing, OU=remote accounts, DC=domain, DC=com" | select -Property userprincipalname
$userlist += Get-ADUser -Filter * -SearchBase "OU=Real Estate and Development, OU=remote accounts, DC=domain, DC=com" | select -Property userprincipalname
$userlist += Get-ADUser -Filter * -SearchBase "OU=Recycling, OU=remote accounts, DC=domain, DC=com" | select -Property userprincipalname
$userlist += Get-ADUser -Filter * -SearchBase "OU=Regional Managers, OU=remote accounts, DC=domain, DC=com" | select -Property userprincipalname
$userlist += Get-ADUser -Filter * -SearchBase "OU=Sourcing, OU=remote accounts, DC=domain, DC=com" | select -Property userprincipalname
#>

#store accounts
#$userlist += Get-ADUser -Filter * -SearchBase "OU=ads users,OU=Store Accounts, DC=domain, DC=com" | select -Property userprincipalname
#$userlist += Get-ADUser -Filter * -SearchBase "OU=Distribution Center Managers,OU=Store Accounts, DC=domain, DC=com" | select -Property userprincipalname
#$userlist += Get-ADUser -Filter * -SearchBase "OU=Distribution Center Users,OU=Store Accounts, DC=domain, DC=com" | select -Property userprincipalname
#$userlist += Get-ADUser -Filter * -SearchBase "OU=Fife,OU=Store Accounts, DC=domain, DC=com" | select -Property userprincipalname
$userlist += Get-ADUser -Filter * -SearchBase "OU=Store Managers,OU=Store Accounts, DC=domain, DC=com" | select -Property userprincipalname
$userlist += Get-ADUser -Filter * -SearchBase "OU=Store Users,OU=Store Accounts, DC=domain, DC=com" | select -Property userprincipalname

#trucking accounts
#$userlist += Get-ADUser -Filter * -SearchBase "OU=Trucking Accounts, DC=domain, DC=com" | select -Property userprincipalname

#$users = get-content
#$users = Read-Host "Enter users name"

#creates an array that contains all of the plans that will be disabled.
$license = @()
$license += "INTUNE_O365"
$license += "RMS_S_ENTERPRISE"
$license += "TEAMS1"
$license += "YAMMER_ENTERPRISE"
$license += "EXCHANGE_S_ENTERPRISE"

#creates the license options using the $license array.
$licenseoptions = New-MsolLicenseOptions -AccountSkuId domain:ENTERPRISEPACK -DisabledPlans $license


foreach ($user in $users) 
{
    
    if ($user.substring(0,1) -eq "1")
    {
        if((get-msoluser -UserPrincipalName $user).licenses.accountskuid -eq $false)
        {
            Set-MsolUserLicense -UserPrincipalName $user -RemoveLicenses domain:ENTERPRISEPACK
            Set-MsolUser -UserPrincipalName $user -UsageLocation "US"
            Set-MsolUserLicense -UserPrincipalName $user -AddLicenses domain:ENTERPRISEPACK -LicenseOptions $licenseoptions
        }
        else
        {
            Set-MsolUser -UserPrincipalName $user -UsageLocation "US"
            Set-MsolUserLicense -UserPrincipalName $user -AddLicenses domain:ENTERPRISEPACK -LicenseOptions $licenseoptions
        }
    }
    else{}

    if ($user.substring(0,1) -eq "2")
    {
        if((get-msoluser -UserPrincipalName $user).licenses.accountskuid -eq $false)
        {
            Set-MsolUserLicense -UserPrincipalName $user -RemoveLicenses domain:ENTERPRISEPACK
            Set-MsolUser -UserPrincipalName $user -UsageLocation "CA"
            Set-MsolUserLicense -UserPrincipalName $user -AddLicenses domain:ENTERPRISEPACK -LicenseOptions $licenseoptions
        }
        else
        {
            Set-MsolUser -UserPrincipalName $user -UsageLocation "CA"
            Set-MsolUserLicense -UserPrincipalName $user -AddLicenses domain:ENTERPRISEPACK -LicenseOptions $licenseoptions
        }
    }
    else{}
    
    if ($user.substring(0,1) -eq "3")
    {
        if((get-msoluser -UserPrincipalName $user).licenses.accountskuid -eq $false)
        {
            Set-MsolUserLicense -UserPrincipalName $user -RemoveLicenses domain:ENTERPRISEPACK
            Set-MsolUser -UserPrincipalName $user -UsageLocation "AU"
            Set-MsolUserLicense -UserPrincipalName $user -AddLicenses domain:ENTERPRISEPACK -LicenseOptions $licenseoptions
        }
        else
        {
            Set-MsolUser -UserPrincipalName $user -UsageLocation "AU"
            Set-MsolUserLicense -UserPrincipalName $user -AddLicenses domain:ENTERPRISEPACK -LicenseOptions $licenseoptions
        }
    }
    else{}
     
    if ($user.substring(0,1) -eq "5")
    {
        if((get-msoluser -UserPrincipalName $user).licenses.accountskuid -eq $false)
        {
            Set-MsolUserLicense -UserPrincipalName $user -RemoveLicenses domain:ENTERPRISEPACK
            Set-MsolUser -UserPrincipalName $user -UsageLocation "US"
            Set-MsolUserLicense -UserPrincipalName $user -AddLicenses domain:ENTERPRISEPACK -LicenseOptions $licenseoptions
        }
        else
        {
            Set-MsolUser -UserPrincipalName $user -UsageLocation "US"
            Set-MsolUserLicense -UserPrincipalName $user -AddLicenses domain:ENTERPRISEPACK -LicenseOptions $licenseoptions
        }
    }
    else{}

    if ($user.substring(0,1) -eq "8")
    {
        if((get-msoluser -UserPrincipalName $user).licenses.accountskuid -eq $false)
        {
            Set-MsolUserLicense -UserPrincipalName $user -RemoveLicenses domain:ENTERPRISEPACK
            Set-MsolUser -UserPrincipalName $user -UsageLocation "US"
            Set-MsolUserLicense -UserPrincipalName $user -AddLicenses domain:ENTERPRISEPACK -LicenseOptions $licenseoptions
        }
        else
        {
            Set-MsolUser -UserPrincipalName $user -UsageLocation "US"
            Set-MsolUserLicense -UserPrincipalName $user -AddLicenses domain:ENTERPRISEPACK -LicenseOptions $licenseoptions
        }
    }
    else{}
}