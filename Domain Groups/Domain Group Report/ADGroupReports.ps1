# LEGAL
<# LICENSE
    MIT License, Copyright 2022 Richard Smith

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
    ADGroupReports.ps1

.SYNOPSIS
    Generates Active Directory group membership and group inventory reports.

.DESCRIPTION
    This public-safe PowerShell script exports:
      - Members of a specified AD group
      - A basic inventory of AD groups
      - An optional full-property AD group inventory

    It is intended as a sanitized example for public GitHub posting. Internal
    names, output paths, and organization-specific values have been replaced
    with placeholders.

    Notes:
      - This script requires the ActiveDirectory PowerShell module.
      - Export-Csv is used for CSV output. Format-Table should not be used when
        creating CSV files.
      - GroupCategory values can vary by context. If you specifically need mail
        distribution groups, consider querying Exchange attributes or using
        Exchange cmdlets instead of assuming all AD groups with a given category
        are distribution groups.

    .PARAMETER TargetGroup
        The AD group whose membership should be exported.

    .PARAMETER OutputDirectory
        Folder where report files will be written.

    .PARAMETER IncludeFullGroupInventory
        Also exports a full-property AD group inventory. This may expose more
        metadata than needed, so review before publishing or sharing.

    .EXAMPLE
        .\ADGroupReports.ps1

    .EXAMPLE
        .\ADGroupReports.ps1 -TargetGroup 'Domain Admins'

    .EXAMPLE
        .\ADGroupReports.ps1 -OutputDirectory 'C:\Reports'

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

#>

[CmdletBinding()]
param(
    [string]$TargetGroup = 'Administrators',
    [string]$OutputDirectory = 'C:\Reports',
    [switch]$IncludeFullGroupInventory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    throw 'The ActiveDirectory module is required but is not installed or available on this system.'
}

Import-Module ActiveDirectory

if (-not (Test-Path -Path $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
}

$groupMembersCsv = Join-Path $OutputDirectory 'AD_GroupMembers.csv'
$groupMembersXml = Join-Path $OutputDirectory 'AD_GroupMembers.xml'
$groupNamesCsv = Join-Path $OutputDirectory 'AD_Groups_NameOnly.csv'
$groupNamesTxt = Join-Path $OutputDirectory 'AD_Groups_NameOnly.txt'
$groupInventoryCsv = Join-Path $OutputDirectory 'AD_Groups_FullInventory.csv'

# Group membership report
Get-ADGroupMember -Identity $TargetGroup |
    Select-Object Name, SamAccountName, ObjectClass, DistinguishedName |
    Export-Csv -Path $groupMembersCsv -NoTypeInformation -Encoding UTF8

Get-ADGroupMember -Identity $TargetGroup |
    Export-Clixml -Path $groupMembersXml

# Name-only group list
$allGroups = Get-ADGroup -Filter * -Properties Name |
    Select-Object Name, SamAccountName, GroupCategory, GroupScope, DistinguishedName

$allGroups |
    Export-Csv -Path $groupNamesCsv -NoTypeInformation -Encoding UTF8

$allGroups |
    Format-Table -AutoSize |
    Out-File -FilePath $groupNamesTxt -Encoding UTF8

# Optional full inventory
if ($IncludeFullGroupInventory) {
    Get-ADGroup -Filter * -Properties * |
        Export-Csv -Path $groupInventoryCsv -NoTypeInformation -Encoding UTF8
}
