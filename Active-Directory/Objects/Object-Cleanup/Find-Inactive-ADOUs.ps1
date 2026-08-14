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
    Find-Inactive-ADOUs.ps1

.DESCRIPTION
    Finds empty Active Directory organizational units (those with no child objects) and reports them.

.FUNCTIONALITY
    Reports empty AD organizational units.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

Import-Module ActiveDirectory

#-------------------------------
# FIND EMPTY OUs
#-------------------------------

# Get empty AD Organizational Units
$OUs = Get-ADOrganizationalUnit -Filter * | ForEach-Object { If ( !( Get-ADObject -Filter * -SearchBase $_ -SearchScope OneLevel) ) { $_ } } | Select-Object Name, DistinguishedName

#-------------------------------
# REPORTING
#-------------------------------

# Export results to CSV
$OUs | Export-Csv C:\temp\InactiveOUs.csv -NoTypeInformation

#-------------------------------
# INACTIVE OUs MANAGEMENT
#-------------------------------

# Delete Inactive OUs
ForEach ($Item in $OUs){
  Remove-ADOrganizationalUnit -Identity $Item.DistinguishedName -Confirm:$false -WhatIf
  Write-Output "$($Item.Name) - Deleted"
}