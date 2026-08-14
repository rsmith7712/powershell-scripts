# LEGAL
<# LICENSE
    MIT License, Copyright 2016 Richard Smith

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the “Software”),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS
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
    o365-license.TempPoint.ps1

.DESCRIPTION
    		Allows o365 administrators to set specific license sets for a user. The computer this script is run from must have the MS Azure PS module as well as the MS Online Connection Assistant module installed.

.FUNCTIONALITY
    		Allows o365 administrators to set specific license sets for a user. The computer this script is run from must have the MS Azure PS module as well as the MS Online Connection Assistant module installed.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#verifies that MSonline module is installed and runs the installer if not.
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

check-msonline

#imports the msonline module
Import-Module MSOnline

#gets the admin creds
Write-Host "----> Enter Admin Credentials"
$cred = Get-Credential

#connects to o365 using credentials provided
Write-Host "----> Connecting to o365"
Connect-MsolService -Credential $cred

#request username, adds "@example.com" automatically.  Verifies that user exists.
do
{
    if ($count -ge 1)
    {
        Write-Host "Unable to find username in AD. Try Again" -ForegroundColor Red
    }
    Write-Host "----> Enter Username"
    $user = read-host
    $username = $user+"@example.com"
    $usertest = dsquery user -samid $user
    if($usertest -eq $null) {$test = $false}
    else {$test = $true}
    $count++
}
while($test -ne $true)

<#
Write-Host "----> Enter Username"
$user = Read-Host
$usertest = dsquery user -samid $use
$username = $user+"@example.com"
#>



#lists available licenses
Write-Host "----> Select Which License to apply"
Write-Host "1. Standard License"
Write-Host "2. Power BI Addon"
Write-Host "3. CRM Standard"
Write-Host "4. Quit"

$license = @()
$license += "INTUNE_O365"
$license += "RMS_S_ENTERPRISE"
$license += "TEAMS1"

$licenseoptions = New-MsolLicenseOptions -AccountSkuId domain:ENTERPRISEPACK -DisabledPlans $license

#applies the license or if license exists, tells admin.
do
{
    $license = Read-Host "Enter Selection"
    switch ($license)
    {
        '1'
        {
            $check = (Get-MsolUser -UserPrincipalName $username).licenses.accountskuid
            if($check -ne "domain:ENTERPRISEPACK")
            {
                Set-MsolUser -UserPrincipalName $username -UsageLocation "US"
                Set-MsolUserLicense -UserPrincipalName $username -AddLicenses "domain:ENTERPRISEPACK" -LicenseOptions $licenseoptions
                Write-Host "license Applied"
            }
            else
            {
                Write-Host "License Already Applied"
            }
        }
        '2'
        { 
            $check = (Get-MsolUser -UserPrincipalName $username).licenses.accountskuid
            if($check -ne "domain:POWER_BI_ADDON")
            {
                Set-MsolUser -UserPrincipalName $username -UsageLocation "US"
                Set-MsolUserLicense -UserPrincipalName $username -AddLicenses "domain:POWER_BI_ADDON"
                Write-Host "license Applied"
            }
            else
            {
                Write-Host "License Already Applied"
            }
        }
        '3'
        {
            $check = (Get-MsolUser -UserPrincipalName $username).licenses.accountskuid
            if($check -ne "domain:CRMSTANDARD")
            {
                Set-MsolUser -UserPrincipalName $username -UsageLocation "US"
                Set-MsolUserLicense -UserPrincipalName $username -AddLicenses "domain:CRMSTANDARD"
                Write-Host "license Applied"
            }
            else
            {
                Write-Host "License Already Applied"
            }
        }
        '4'
        {
            break
        }
    }
}
until ($license -eq '4')

Write-host "----> User now has the following licenses"
(Get-MsolUser -UserPrincipalName $username).licenses.accountskuid