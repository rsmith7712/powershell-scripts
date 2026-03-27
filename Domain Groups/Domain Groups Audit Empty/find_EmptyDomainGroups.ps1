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
    find_EmptyDomainGroups.ps1

.DESCRIPTION
    Search AD and report all empty domain groups

.FUNCTIONALITY
    Code will produce all the empty groups in your domain and export it to a csv file.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

    URL #1
    https://www.enterprisedaddy.com/2015/02/find-empty-groups-in-active-directory-using-powershell/

    REFERENCE URL: MICROSOFT, Global Catalog and LDAP Searches
    https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-2000-server/cc978012(v=technet.10)?redirectedfrom=MSDN

    URL #2
    https://www.techcrafters.com/portal/en/kb/articles/cleanup-empty-groups-active-directory-powershell#Cleanup_Empty_AD_Groups_with_PowerShell   

#>

Import-Module Activedirectory;
Get-ADGroup -filter * -Properties members, DistinguishedName | where {-Not $_.members} | Select Name, DistinguishedName |
Export-Csv -NoTypeInformation C:\report_EmptyDomainGroups.csv;