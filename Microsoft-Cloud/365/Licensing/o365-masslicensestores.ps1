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
    o365-masslicensestores.ps1

.DESCRIPTION
    Assigns Microsoft 365 licenses in bulk to store and account-OU users.

.FUNCTIONALITY
    Bulk-assigns Microsoft 365 licenses to store users.

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

#$userlist += Get-ADUser -Filter * -SearchBase "OU=Store Managers,OU=Store Accounts, DC=domain, DC=com" | select -Property userprincipalname | out-string -stream
#$userlist += Get-ADUser -Filter * -SearchBase "OU=Store Users,OU=Store Accounts, DC=domain, DC=com" | select -Property userprincipalname | out-string -stream

#trucking accounts
#$userlist += Get-ADUser -Filter * -SearchBase "OU=Trucking Accounts, DC=domain, DC=com" | select -Property userprincipalname

#$users = get-content
#$userlist = Read-Host "Enter users name"

# Create DateString variable to append to end of each file generated
$DateString = get-date -Format HHmmss

# Create global variable: Logfile :and point it toward the ErrorLogfile CSV with _$DateString at end
$Global:Logfile = "C:\o365_PostLicensingAssignment_LogFile_$DateString.csv"
New-Item -Path $Global:Logfile -ItemType File -Force
Add-Content $Global:Logfile "UserAccount, Status"

FUNCTION Append-Log($message)
{
	Add-Content $Global:Logfile "$message"
}

$userlist = Get-Content C:\temp\userlist.txt
$userlist = $userlist.Trim()
$userlist = $userlist | ? {$_}

#Connect to MSOL with admin creds
Connect-MsolService

#creates an array that contains all of the plans that will be disabled.
$license = @()
$license += "INTUNE_O365"
$license += "RMS_S_ENTERPRISE"
$license += "TEAMS1"
#$license += "YAMMER_ENTERPRISE"
#$license += "EXCHANGE_S_ENTERPRISE"

#creates the license options using the $license array.
$licenseoptions = New-MsolLicenseOptions -AccountSkuId domain:ENTERPRISEPACK -DisabledPlans $license

foreach ($user in $userlist) 
{
    
    if ($user.substring(0,1) -eq "1")
    {
        if((get-msoluser -UserPrincipalName $user).licenses.accountskuid -eq "domain:ENTERPRISEPACK")
        {
            Set-MsolUserLicense -UserPrincipalName $user -RemoveLicenses domain:ENTERPRISEPACK
            Set-MsolUser -UserPrincipalName $user -UsageLocation "US"
            Set-MsolUserLicense -UserPrincipalName $user -AddLicenses domain:ENTERPRISEPACK -LicenseOptions $licenseoptions
            
            # License application check 
		    $Check = (Get-MsolUser -UserPrincipalName $user).licenses.AccountSkuID
		    If ($Check -NE "domain:ENTERPRISEPACK")
		    {
			    write-host "Failed" -ForegroundColor Red
			    $failures += $user
			    Append-Log "$user, Failed"
		    }
		    else
		    {
			    write-host "Success" -ForegroundColor Green
			    Append-Log "$user, License Added"
		    }
        }
        else
        {
            Set-MsolUser -UserPrincipalName $user -UsageLocation "US"
            Set-MsolUserLicense -UserPrincipalName $user -AddLicenses domain:ENTERPRISEPACK -LicenseOptions $licenseoptions
            # License application check 
		    $Check = (Get-MsolUser -UserPrincipalName $user).licenses.AccountSkuID
		    If ($Check -NE "domain:ENTERPRISEPACK")
		    {
			    write-host "Failed" -ForegroundColor Red
			    $failures += $user
			    Append-Log "$user, Failed"
		    }
		    else
		    {
			    write-host "Success" -ForegroundColor Green
			    Append-Log "$user, License Added"
		    }
        }
    }
    else{}

    if ($user.substring(0,1) -eq "2")
    {
        if((get-msoluser -UserPrincipalName $user).licenses.accountskuid -eq "domain:ENTERPRISEPACK")
        {
            Set-MsolUserLicense -UserPrincipalName $user -RemoveLicenses domain:ENTERPRISEPACK
            Set-MsolUser -UserPrincipalName $user -UsageLocation "CA"
            Set-MsolUserLicense -UserPrincipalName $user -AddLicenses domain:ENTERPRISEPACK -LicenseOptions $licenseoptions
            # License application check 
		    $Check = (Get-MsolUser -UserPrincipalName $user).licenses.AccountSkuID
		    If ($Check -NE "domain:ENTERPRISEPACK")
		    {
			    write-host "Failed" -ForegroundColor Red
			    $failures += $user
			    Append-Log "$user, Failed"
		    }
		    else
		    {
			    write-host "Success" -ForegroundColor Green
			    Append-Log "$user, License Added"
		    }
        }
        else
        {
            Set-MsolUser -UserPrincipalName $user -UsageLocation "CA"
            Set-MsolUserLicense -UserPrincipalName $user -AddLicenses domain:ENTERPRISEPACK -LicenseOptions $licenseoptions
            # License application check 
		    $Check = (Get-MsolUser -UserPrincipalName $user).licenses.AccountSkuID
		    If ($Check -NE "domain:ENTERPRISEPACK")
		    {
			    write-host "Failed" -ForegroundColor Red
			    $failures += $user
			    Append-Log "$user, Failed"
		    }
		    else
		    {
			    write-host "Success" -ForegroundColor Green
			    Append-Log "$user, License Added"
		    }
        }
    }
    else{}
    
    if ($user.substring(0,1) -eq "3")
    {
        if((get-msoluser -UserPrincipalName $user).licenses.accountskuid -eq "domain:ENTERPRISEPACK")
        {
            Set-MsolUserLicense -UserPrincipalName $user -RemoveLicenses domain:ENTERPRISEPACK
            Set-MsolUser -UserPrincipalName $user -UsageLocation "AU"
            Set-MsolUserLicense -UserPrincipalName $user -AddLicenses domain:ENTERPRISEPACK -LicenseOptions $licenseoptions
            # License application check 
		    $Check = (Get-MsolUser -UserPrincipalName $user).licenses.AccountSkuID
		    If ($Check -NE "domain:ENTERPRISEPACK")
		    {
			    write-host "Failed" -ForegroundColor Red
			    $failures += $user
			    Append-Log "$user, Failed"
		    }
		    else
		    {
			    write-host "Success" -ForegroundColor Green
			    Append-Log "$user, License Added"
		    }
        }
        else
        {
            Set-MsolUser -UserPrincipalName $user -UsageLocation "AU"
            Set-MsolUserLicense -UserPrincipalName $user -AddLicenses domain:ENTERPRISEPACK -LicenseOptions $licenseoptions
            # License application check 
		    $Check = (Get-MsolUser -UserPrincipalName $user).licenses.AccountSkuID
		    If ($Check -NE "domain:ENTERPRISEPACK")
		    {
			    write-host "Failed" -ForegroundColor Red
			    $failures += $user
			    Append-Log "$user, Failed"
		    }
		    else
		    {
			    write-host "Success" -ForegroundColor Green
			    Append-Log "$user, License Added"
		    }
        }
    }
    else{}
     
    if ($user.substring(0,1) -eq "5")
    {
        if((get-msoluser -UserPrincipalName $user).licenses.accountskuid -eq "domain:ENTERPRISEPACK")
        {
            Set-MsolUserLicense -UserPrincipalName $user -RemoveLicenses domain:ENTERPRISEPACK
            Set-MsolUser -UserPrincipalName $user -UsageLocation "US"
            Set-MsolUserLicense -UserPrincipalName $user -AddLicenses domain:ENTERPRISEPACK -LicenseOptions $licenseoptions
            # License application check 
		    $Check = (Get-MsolUser -UserPrincipalName $user).licenses.AccountSkuID
		    If ($Check -NE "domain:ENTERPRISEPACK")
		    {
			    write-host "Failed" -ForegroundColor Red
			    $failures += $user
			    Append-Log "$user, Failed"
		    }
		    else
		    {
			    write-host "Success" -ForegroundColor Green
			    Append-Log "$user, License Added"
		    }
        }
        else
        {
            Set-MsolUser -UserPrincipalName $user -UsageLocation "US"
            Set-MsolUserLicense -UserPrincipalName $user -AddLicenses domain:ENTERPRISEPACK -LicenseOptions $licenseoptions
            # License application check 
		    $Check = (Get-MsolUser -UserPrincipalName $user).licenses.AccountSkuID
		    If ($Check -NE "domain:ENTERPRISEPACK")
		    {
			    write-host "Failed" -ForegroundColor Red
			    $failures += $user
			    Append-Log "$user, Failed"
		    }
		    else
		    {
			    write-host "Success" -ForegroundColor Green
			    Append-Log "$user, License Added"
		    }
        }
    }
    else{}

    if ($user.substring(0,1) -eq "8")
    {
        if((get-msoluser -UserPrincipalName $user).licenses.accountskuid -eq "domain:ENTERPRISEPACK")
        {
            Set-MsolUserLicense -UserPrincipalName $user -RemoveLicenses domain:ENTERPRISEPACK
            Set-MsolUser -UserPrincipalName $user -UsageLocation "US"
            Set-MsolUserLicense -UserPrincipalName $user -AddLicenses domain:ENTERPRISEPACK -LicenseOptions $licenseoptions
            # License application check 
		    $Check = (Get-MsolUser -UserPrincipalName $user).licenses.AccountSkuID
		    If ($Check -NE "domain:ENTERPRISEPACK")
		    {
			    write-host "Failed" -ForegroundColor Red
			    $failures += $user
			    Append-Log "$user, Failed"
		    }
		    else
		    {
			    write-host "Success" -ForegroundColor Green
			    Append-Log "$user, License Added"
		    }
        }
        else
        {
            Set-MsolUser -UserPrincipalName $user -UsageLocation "US"
            Set-MsolUserLicense -UserPrincipalName $user -AddLicenses domain:ENTERPRISEPACK -LicenseOptions $licenseoptions
            # License application check 
		    $Check = (Get-MsolUser -UserPrincipalName $user).licenses.AccountSkuID
		    If ($Check -NE "domain:ENTERPRISEPACK")
		    {
			    write-host "Failed" -ForegroundColor Red
			    $failures += $user
			    Append-Log "$user, Failed"
		    }
		    else
		    {
			    write-host "Success" -ForegroundColor Green
			    Append-Log "$user, License Added"
		    }
        }
    }
    else{}
}