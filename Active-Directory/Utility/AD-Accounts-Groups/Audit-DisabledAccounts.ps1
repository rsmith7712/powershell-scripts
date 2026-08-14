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
    Audit-DisabledAccounts.ps1

.DESCRIPTION
    Reports disabled Active Directory user accounts, excluding a defined set of retention OUs.

.FUNCTIONALITY
    Audits disabled AD accounts with OU exclusions.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>


$ExcludedOUs = @(
    "OU=DoNotDelete,OU=Disabled Accounts,OU=Domain Services,DC=DOMAIN,DC=com",
    "OU=Functionally_Disabled,OU=Service Accounts,OU=Domain Services,DC=DOMAIN,DC=com",
    "OU=TempCloseADS,OU=Disabled Accounts,OU=Domain Services,DC=DOMAIN,DC=com",
    "OU=_svcAccts_Users,OU=Disabled Accounts,OU=Domain Services,DC=DOMAIN,DC=com"
    )

$DisabledOU = "OU=Disabled Accounts,OU=Domain Services,DC=DOMAIN,DC=com"

$Users = Search-ADAccount -AccountDisabled -UsersOnly | Select-Object -Property DistinguishedName

ForEach($User in $Users)
{
    If($ExcludedOUs -contains $($User.DistinguishedName -replace '^.+?(?<!\\),','')) #Strips down to OU
    {
        #Don't Touch
    }
    else 
    {
        Move-ADObject -Identity $User.DistinguishedName -TargetPath $DisabledOU
    }
}