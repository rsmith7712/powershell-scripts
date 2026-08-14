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
    Audit.disable.AD.users.ps1

.DESCRIPTION
    Reads a list of users and logs each account's name, enabled state and UPN for an audit of accounts to be disabled.

.FUNCTIONALITY
    Audits AD user accounts prior to disabling.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

$Users = Get-Content C:\temp\text\userlist.txt

ForEach ($User in $Users)

{ $ADUser = $null

$ADUser = Get-ADUser $User -Properties Description | select Name , Enabled , UserPrincipalName

If ($ADUser)

{ Add-Content C:\temp\text\Auditusers4.17.20.log -Value " $ADUser - Status"

}

Else

{ Add-Content C:\temp\text\Auditusers4.17.20.txt -Value "$User -- not in Active Directory"

}

}