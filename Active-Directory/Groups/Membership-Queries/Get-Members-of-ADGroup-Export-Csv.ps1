# LEGAL
<# LICENSE
    MIT License, Copyright 2023 Richard Smith

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
    Get-Members-of-ADGroup-Export-Csv.ps1

.DESCRIPTION
    Exports the members of the Enterprise Admins Active Directory group to CSV.

.FUNCTIONALITY
    Exports an AD group's members to CSV.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

<#
NAME
    Get-Members-of-ADGroup.ps1
#>

#import module
Import-Module ActiveDirectory

#list all members of child groups
#Get-ADGroupMember -Identity "Enterprise Admins" -Recursive


#Export List of Active Directory Group Members to CSV
Get-ADGroupMember -Identity "Enterprise Admins" | Select-Object Name,ObjectClass,DistinguishedName | Export-CSV -Path “C:\temp\EXAMPLE-ADGroupMembers-EnterpriseAdmins.csv” -NoTypeInformation

Get-ADGroupMember -Identity "Schema Admins" | Select-Object Name,ObjectClass,DistinguishedName | Export-CSV -Path “C:\temp\EXAMPLE-ADGroupMembers-SchemaAdmins.csv” -NoTypeInformation

Get-ADGroupMember -Identity "Domain Admins" | Select-Object Name,ObjectClass,DistinguishedName | Export-CSV -Path “C:\temp\EXAMPLE-ADGroupMembers-DomainAdmins.csv” -NoTypeInformation


