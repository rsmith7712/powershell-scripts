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
    click-click-boom-EnterprisePwReset.ps1

.DESCRIPTION
    Forces a password reset at next logon for all Active Directory users in a domain or specified OU.

.FUNCTIONALITY
    Forces AD password reset at next logon.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

<#
.NAME
    - click-click-boom-EnterprisePwReset.ps1

.PURPOSE
    - Forced reset of all Active Directory User accounts passwords at next logon.

    - Target by either entire domain or by specific OU


#>


#Get-ADUser -Filter * -SearchBase "OU=Users,DC=Domain,DC=com" | set-aduser -ChangePasswordAtLogon $True -WhatIf

Get-ADUser -Filter * -SearchBase "DC=Domain,DC=com" | set-aduser -ChangePasswordAtLogon $True -WhatIf