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
    getGroupsADUserIsAMemberOf.ps1

.DESCRIPTION
    Defines a function that recursively resolves all Active Directory groups a user or object is a member of, including nested groups.

.FUNCTIONALITY
    Recursively lists a user's AD group memberships.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

function Get-ADPrincipalGroupMembershipRecursive( ) {

    Param(
        [string] $dsn,
        [array]$groups = @()
    )

    $obj = Get-ADObject $dsn -Properties memberOf

    foreach( $groupDsn in $obj.memberOf ) {

        $tmpGrp = Get-ADObject $groupDsn -Properties memberOf

        if( ($groups | where { $_.DistinguishedName -eq $groupDsn }).Count -eq 0 ) {
            $groups +=  $tmpGrp           
            $groups = Get-ADPrincipalGroupMembershipRecursive $groupDsn $groups
        }
    }

    return $groups
}

# Simple Example of how to use the function
$username = Read-Host -Prompt "Enter a username"
$groups   = Get-ADPrincipalGroupMembershipRecursive (Get-ADUser $username).DistinguishedName
$groups | Sort-Object -Property name | Format-Table | Out-File C:\getGroupsADUserIsAMemberOf.csv