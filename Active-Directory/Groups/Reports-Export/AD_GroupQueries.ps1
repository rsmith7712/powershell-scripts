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
    AD_GroupQueries.ps1

.DESCRIPTION
    Runs a set of Active Directory group queries, exporting group-membership and distribution-group listings to CSV and text files.

.FUNCTIONALITY
    Exports AD group-membership and distribution-group reports.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>



#Group Membership Reports
#Get-ADGroupMember -Identity administrators | Export-Clixml C:\AD_GroupAdmins.xml
Get-ADGroupMember -Identity administrators | Format-Table -AutoSize |Out-File C:\AD_GroupAdmins.csv
Get-ADGroupMember -Identity administrators | Format-Table -AutoSize |Out-File C:\ADGroup_DESKTOP_CORP.csv


#Distribution Group List
#Get-ADGroup -Filter 'GroupCategory -eq 0' -Properties * | Export-Clixml C:\AD_DistributionGroups.xml
#Get-ADGroup -Filter * -Properties * | Format-Table -AutoSize | Out-File C:\AD_DistributionGroups.csv
#Get-ADGroup -Filter * -Properties * | Format-Table -AutoSize | Out-File C:\AD_DistributionGroups.txt
Get-ADGroup -Filter * -Properties Name | Format-Table -AutoSize -Verbose | Out-File C:\AD_DistributionGroups_NAME.txt
Get-ADGroup -Filter * -Properties Name | Format-Table -AutoSize -Verbose | Out-File C:\AD_DistributionGroups_NAME.csv
Get-ADGroup -Filter * -Properties * | Format-Table -AutoSize -Verbose | Out-File C:\AD_DistributionGroups_NAME.txt


#Distribution Group Members List
#Get-ADGroup -Filter 'GroupCategory -eq 0' -Properties * Get-msoluser | Export-Clixml C:\AD_DistributionGroupMembers.xml
Get-ADGroup -Filter 'GroupCategory -eq 0' -Properties * | Out-File C:\AD_DistributionGroupMembers.csv
#Get-ADGroup -Filter * -Properties * Get-ADuser | Format-Table -AutoSize | Out-File C:\AD_DistributionGroupMembers.csv

#DESKTOP_CORP



