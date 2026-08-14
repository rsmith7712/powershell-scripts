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
    Get-ADuser-PasswordAccountInfo.ps1

.DESCRIPTION
    Queries all Active Directory user objects and exports password and account attributes (DN, display name, SAM account name, etc.) to CSV.

.FUNCTIONALITY
    Exports AD user password and account info to CSV.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

<#
.NAME
    Get-ADuser-PasswordAccountInfo.ps1

.PURPOSE
    Query AD for all user objects and exporting them to CSV with the following attributes:
    - DistinguishedName
    -- Displays user objects current OU

    - DisplayName
    -- Displays users display name in Active Directory

    - SamAccountName
    -- Displays users login name in Active Directory

    - PasswordExpired
    -- True = 
    -- False = 

    - Enabled
    -- True = User Object is Enabled in Active Directory
    -- False = User Object is Disabled in Active Directory

    - PasswordLastSet
    -- Displays last time user reset their password

    - PasswordNeverExpires
    -- True = Active Directory user account password is set to never expire
    -- False = Active Directory user account password is set to expire based on the GPO: Default Domain Policy 

#>

Get-ADUser -filter * -properties PasswordExpired, Enabled, PasswordLastSet, PasswordNeverExpires | 
sort-object PasswordLastSet | select-object Name, SamAccountName, PasswordExpired, Enabled, PasswordLastSet, PasswordNeverExpires, DistinguishedName | 
Export-csv -path c:\temp\ADuser-PasswordAccountInfo.csv -Append -Encoding UTF8