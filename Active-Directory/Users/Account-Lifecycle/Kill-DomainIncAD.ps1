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
    Kill-DomainIncAD.ps1

.SYNOPSIS
  Scrubs "Domain, Inc." from user accounts in AD.
 
.NOTES
  Version:        2.0
  Author:         user26
  Creation Date:  07/26/17
  Purpose/Change: Searching all of AD.

.HISTORY
  Version:        1.0 (07/26/17)
  Purpose/Change: Initial build.

.FUNCTIONALITY
    Scrubs "Domain, Inc." from user accounts in AD.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Initializations
#########################################
$script:script_filepath 	= $MyInvocation.MyCommand.Path
$script:script_dir 			= Split-Path -Parent $script:script_filepath
$ErrorActionPreference 		= "SilentlyContinue"

# Logging
#########################################
$Script:Logfile = "C:\temp\Kill_DomainInc_AD.csv"
New-Item -Path $Script:Logfile -ItemType File -Force
Add-Content $Script:Logfile "Username, Old Company Entry, Action Taken"
function Append-Log($message)
{
    Add-Content $Script:LogFile "$message"
}

# Script
#########################################
$OU = "DC=DOMAIN,DC=com"
$New = "DOMAIN, Inc."
#$Count = 0

$Users = Get-ADUser -Searchbase $OU -Filter 'Company -like "*domain*"' -Properties Company,samaccountname

ForEach($User in $Users)
{
    Set-ADUser $User.samaccountname -Company $New
    Switch($?)
    {
        $True {Append-Log "$($User.samaccountname),""$($User.Company)"",Changed"}
        $False {Append-Log "$($User.samaccountname),""$($User.Company)"",Failed to Change"}
    }
	#$Count ++
	#If($Count -gt 5){Exit}
}