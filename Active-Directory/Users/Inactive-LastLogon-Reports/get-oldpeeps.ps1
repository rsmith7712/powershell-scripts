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
    get-oldpeeps.ps1

.DESCRIPTION
    Defines a function to find inactive Active Directory users under a given search base.

.FUNCTIONALITY
    Finds inactive AD users under a search base.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>



Import-Module ActiveDirectory


function get-oldpeeps {
	
	param (
		
		[Parameter(Mandatory = $False)]
		[string]$searchbase,
		[Parameter(Mandatory = $False)]
		[Int]$xdays,
		[Parameter(Mandatory = $False)]
		[Switch]$allusers
		
	)
	

	$today = get-date -uformat "%Y/%m/%d"
	if ($xdays) { $age = (get-date).AddDays(- $xdays) } else { $age = (get-date).AddDays(-90) }
	$expire = (get-date).AddDays(-1)
	$ParkingOU = "OU=30Days, OU=Disabled Accounts, OU=Domain Services, DC=Domain, DC=com"
	
#use a switch statement so you don't have to continuously comment sections of code. 
	
	switch ($searchbase) {
		
		MIT{ $ou = "OU=MIT, OU=Service Accounts, OU=Domain Services, DC=Domain, DC=com" }
		Laptop{ $ou = "OU=Laptop, OU=IS, OU=Corporate Computers, DC=Domain, DC=com" }
		Remote{ $ou = "OU=Remote Accounts, DC=Domain, DC=com" }
	        ''{$ou = 'dc=Savergs,dc=com'}
		
	}
	
#This is called a here string. Play with it. Easier to code without losing track of qoutes and plus's
	
	$userDesc = @"
Disabled Inactive $today Moved From OU $ou
"@
	
	if ($allusers) {
		Get-ADUser -Filter * -Properties DisplayName, MemberOf | % {
			
			[PSCustomObject]@{
				UserName = $_.DisplayName
				Groups = ($_.MemberOf | Get-ADGroup | Select -ExpandProperty Name) -join ","
			}
			
		}
		
#dont hardcode export file into scripts. return info from function then | Export-Csv C:\ADUser_GroupMembership_Rpt.csv -NTI
		
	} else {
		
		$Users = Get-ADUser -SearchBase $ou -Properties memberof, PasswordNeverExpires, WhenCreated, PasswordLastSet, LastLogonDate -Filter {
			(LastLogonDate -gt $age)
			-AND (PasswordLastSet -gt $age)
			-AND (Enabled -eq $True)
			-AND (PasswordNeverExpires -eq $false)
			-AND (WhenCreated -le $age)
		}
		
#revise filter whencreated less than 90 could not result in users lastlogondate being greater than 90?
		
		$users | ForEach-Object {
			
			Set-ADUser $_ -AccountExpirationDate $expire -Description $userdesc -WhatIf
			Move-ADObject $_ -TargetPath $ParkingOU -WhatIf
			$_ | select *, @{ l = 'Groups'; e = { (($_.memberof | Get-ADGroup).Name) -join '; ' } }
		}
		
	}
	
	
}

Export-Csv C:\ADUser_GroupMembership_Rpt.csv -NTI
