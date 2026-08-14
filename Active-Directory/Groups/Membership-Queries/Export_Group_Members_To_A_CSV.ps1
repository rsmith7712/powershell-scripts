# LEGAL
<# LICENSE
    MIT License, Copyright 2022 Richard Smith

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
    Export_Group_Members_To_A_CSV.ps1

.DESCRIPTION
    Exports the members of the DESKTOP_CORP group (by name and SAM account name, including nested members) to CSV.

.FUNCTIONALITY
    Exports a group's members to CSV.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Import-Module activedirectory

# export group members to a csv file
Get-ADGroupMember -identity “DESKTOP_CORP” | select name |
 Export-csv -path C:\DESKTOP_CORP_Name.csv -NoTypeInformation;

# list out the users by samaccountname 
Get-ADGroupMember -identity “DESKTOP_CORP” | select samaccountname |
 Export-csv -path C:\DESKTOP_CORP_SAMAccountName.csv -NoTypeInformation;

# enumerate all the nested group members and add them to the list
Get-ADGroupMember -identity “DESKTOP_CORP” -recursive | select name, samaccountname |
 Export-csv -path C:\DESKTOP_CORP_Recursive.csv -NoTypeInformation