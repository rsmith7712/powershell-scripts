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
    userpull.ps1

.DESCRIPTION
    Builds a combined list of user principal names from the corporate, partner, external and temp account OUs in Active Directory.

.FUNCTIONALITY
    Compiles a UPN list across multiple AD OUs.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#corporate accounts
$userlist += (Get-ADUser -Filter * -SearchBase "OU=corporate accounts, DC=domain, DC=com").userprincipalname

#partner accounts
$userlist += (Get-ADUser -Filter * -SearchBase "OU=domain retail, OU=partner accounts, DC=domain, DC=com").userprincipalname
#$userlist += (Get-ADUser -Filter * -SearchBase "OU=partner1, OU=partner accounts, DC=domain, DC=com").userprincipalname
#$userlist += (Get-ADUser -Filter * -SearchBase "OU=partner2, OU=partner accounts, DC=domain, DC=com").userprincipalname
$userlist += (Get-ADUser -Filter * -SearchBase "OU=partner3, OU=partner accounts, DC=domain, DC=com").userprincipalname

#Domain Services
$userlist += (Get-ADUser -Filter * -SearchBase "OU=External Accounts, OU=Domain Services, DC=domain, DC=com").userprincipalname
$userlist += (Get-ADUser -Filter * -SearchBase "OU=Corptemps, OU=Temp Accounts, OU=Domain Services, DC=domain, DC=com").userprincipalname
$userlist += (Get-ADUser -Filter * -SearchBase "OU=Users, OU=Service Accounts, OU=Domain Services, DC=domain, DC=com").userprincipalname

#remote accounts
#$userlist += (Get-ADUser -Filter * -SearchBase "OU=ads leads, OU=remote accounts, DC=domain, DC=com").userprincipalname
$userlist += (Get-ADUser -Filter * -SearchBase "OU=ads management, OU=remote accounts, DC=domain, DC=com").userprincipalname
$userlist += (Get-ADUser -Filter * -SearchBase "OU=directors, OU=remote accounts, DC=domain, DC=com").userprincipalname
$userlist += (Get-ADUser -Filter * -SearchBase "OU=District Managers, OU=remote accounts, DC=domain, DC=com").userprincipalname
$userlist += (Get-ADUser -Filter * -SearchBase "OU=Human Resources, OU=remote accounts, DC=domain, DC=com").userprincipalname
$userlist += (Get-ADUser -Filter * -SearchBase "OU=Inventory Management and Logistics, OU=remote accounts, DC=domain, DC=com").userprincipalname
$userlist += (Get-ADUser -Filter * -SearchBase "OU=Loss Prevention, OU=remote accounts, DC=domain, DC=com").userprincipalname
$userlist += (Get-ADUser -Filter * -SearchBase "OU=Marketing, OU=remote accounts, DC=domain, DC=com").userprincipalname
$userlist += (Get-ADUser -Filter * -SearchBase "OU=Real Estate and Development, OU=remote accounts, DC=domain, DC=com").userprincipalname
$userlist += (Get-ADUser -Filter * -SearchBase "OU=Recycling, OU=remote accounts, DC=domain, DC=com").userprincipalname
$userlist += (Get-ADUser -Filter * -SearchBase "OU=Regional Managers, OU=remote accounts, DC=domain, DC=com").userprincipalname
$userlist += (Get-ADUser -Filter * -SearchBase "OU=Sourcing, OU=remote accounts, DC=domain, DC=com").userprincipalname

#store accounts
#$userlist += (Get-ADUser -Filter * -SearchBase "OU=ads users,OU=Store Accounts, DC=domain, DC=com").userprincipalname
$userlist += (Get-ADUser -Filter * -SearchBase "OU=Distribution Center Managers,OU=Store Accounts, DC=domain, DC=com").userprincipalname
$userlist += (Get-ADUser -Filter * -SearchBase "OU=Distribution Center Users,OU=Store Accounts, DC=domain, DC=com").userprincipalname
$userlist += (Get-ADUser -Filter * -SearchBase "OU=Fife,OU=Store Accounts, DC=domain, DC=com").userprincipalname
$userlist += (Get-ADUser -Filter * -SearchBase "OU=Store Managers,OU=Store Accounts, DC=domain, DC=com").userprincipalname
$userlist += (Get-ADUser -Filter * -SearchBase "OU=Store Users,OU=Store Accounts, DC=domain, DC=com").userprincipalname

#trucking accounts
$userlist += (Get-ADUser -Filter * -SearchBase "OU=Trucking Accounts, DC=domain, DC=com").userprincipalname

write-host $userlist.count

$userlist | Out-File C:\temp\USERPULL.txt