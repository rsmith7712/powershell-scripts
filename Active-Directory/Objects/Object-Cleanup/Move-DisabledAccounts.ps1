# LEGAL
<# LICENSE
    MIT License, Copyright 2017 Richard Smith

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
    Move-DisabledAccounts.ps1

.SYNOPSIS
  Audits ActiveDirectory for disabled user accounts.
 
.DESCRIPTION
  Disabled user accounts found outside of the excluded OUs will be moved to Disabled Accounts.
 
.NOTES
  Version:        1.0
  Author:         user4@example.com
  Creation Date:  08/25/2017
  Purpose/Change: Working Script.

.HISTORY
  Version:        0.1 (08/25/2017)
  Purpose/Change: Initial Script Development.

.FUNCTIONALITY
    Disabled user accounts found outside of the excluded OUs will be moved to Disabled Accounts.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# ----------------------------------------------------------------------------------------------
# Initializations
$script:script_filepath = $MyInvocation.MyCommand.Path
$script:script_dir = Split-Path -Parent $script:script_filepath
$ErrorActionPreference = "SilentlyContinue"

# ----------------------------------------------------------------------------------------------
# Logging
$Date = Get-Date -Format "MM-dd-yy"
$Script:LogFile = "C:\temp\AuditAD_$Date.log"
function Append-Log($message){
	Add-Content $Script:LogFile "`n$message"
    }

$ExcludedOUs = @( # Add any OUs you want excluded from movement here.
    "OU=DoNotDelete,OU=Disabled Accounts,OU=Domain Services,DC=DOMAIN,DC=com",
    "OU=Functionally_Disabled,OU=Service Accounts,OU=Domain Services,DC=DOMAIN,DC=com",
    "OU=TempCloseADS,OU=Disabled Accounts,OU=Domain Services,DC=DOMAIN,DC=com",
    "OU=_svcAccts_Users,OU=Disabled Accounts,OU=Domain Services,DC=DOMAIN,DC=com",
    "OU=Disabled Accounts,OU=Domain Services,DC=DOMAIN,DC=com",
    "OU=ClosedADS,OU=Disabled Accounts,OU=Domain Services,DC=DOMAIN,DC=com"
    )

#This is where the accounts will be moved.
$DisabledOU = "OU=Disabled Accounts,OU=Domain Services,DC=DOMAIN,DC=com"

#Seaches AD for disabled user accounts and grabs the SamAccountName and DistinguishedName.
$Users = Search-ADAccount -AccountDisabled -UsersOnly | Select-Object -Property SamAccountName,DistinguishedName

ForEach($User in $Users)
{
    $CurrentOU = $User.DistinguishedName -replace '^.+?(?<!\\),','' #Strips down to OU
    If($ExcludedOUs -contains $CurrentOU)
    {
        #If the account is in an ExcludedOU, the script leaves it alone.
        Append-Log "$($User.SamAccountName) is in an Excluded OU and will not be moved."
    }
    else 
    {
        Move-ADObject -Identity $User.DistinguishedName -TargetPath $DisabledOU
        Append-Log "$($User.SamAccountName) was in $CurrentOU and has been moved to the Disabled Accounts OU."
    }
}