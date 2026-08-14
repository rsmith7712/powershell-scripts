# LEGAL
<# LICENSE
    MIT License, Copyright 2018 Richard Smith

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
    ADCleanUp_GeneralReconQuery_2.ps1

.DESCRIPTION
    		A description of the file.

.FUNCTIONALITY
    		A description of the file.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

<#

.NAME
    ADCleanUp_GeneralReconQuery.ps1

.SUMMARY
    Query ADUsers / ADGroup / ADComputer for older than
    180-days then export to CSV, otherwise ignore

#>

#Import Modules
Import-Module ActiveDirectory


#Create Variables
$OU = "DC=Domain,DC=com"
$Date = get-date
$NumberDays = 180
#$TBD = #Catch all for users/groups/computers to get RFC'd

#Main

#Query to pull all the ADUser Objects that have been inactive for greater than 180-days and export to CSV
Get-ADUser -Filter * -SearchBase $OU -Properties SAMAccountName, GivenName, SurName, LastLogonDate |
? { $_.LastLogonDate -gt $Date.AddDays(-180) } |
Select SAMAccountName, GivenName, SurName, LastLogonDate | Export-Csv "c:\Temp\ADCleanUP_6Month_Inactive_User_Object_Report.csv" -NoTypeInformation


#Query to pull all the ADGroup Objects that are empty and export to CSV
$Groups = Get-ADGroup -Filter { Members -notlike "*" } -SearchBase $OU | Select-Object Name, GroupCategory, DistinguishedName
$Groups | Export-Csv "C:\Temp\ADCleanUP_Empty_and_Inactive_ADGroups.csv" -NoTypeInformation


#Query to pull all the ADComputer Objects that are empty and export to CSV
Get-ADComputer -Properties LastLogonDate -Filter * | Where LastLogonDate -LT ($Date).AddDays(-180) |
Export-Csv "c:\Temp\ADCleanUP_6Month_Inactive_Computer_Object_Report.csv" -NoTypeInformation


#Query for computers that have been inactive for greater than 180-days
Get-ADComputer -Filter * -SearchBase "DC=Domain,DC=com" |
Where-Object { $_.InactiveFor -le (Get-Date).adddays(- $NumberDays) } |
Where-Object { $_.ParentContainer -notmatch "DC=Domain,DC=com" } |
Select-Object Name, ParentContainer, Department, Office, Description, InactiveFor, LastLogon, AccountIsDisabled |
Export-Csv "C:\Temp\file.csv" -noTypeInformation



<#
# Delete Inactive Crap
ForEach ($Item in $TBD){
  Remove-ADGroup -Identity $Item.DistinguishedName -Confirm:$false -WhatIf
  Write-Output "$($Item.Name) - Click Click BOOM Donkey Kong!!!"
}
#>

