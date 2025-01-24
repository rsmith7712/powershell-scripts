﻿# LEGAL
<# LICENSE
    MIT License, Copyright 2023 Richard Smith

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
	AD-getPasswordStatusForEnterpriseAdmins.ps1

.SYNOPSIS
    - Get the members of the "Enterprise Admins" group
	- Query password expiration status
	- Results to console

.FUNCTIONALITY
    Prompts for Input

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

# Get the members of the "Enterprise Admins" group
$groupMembers = Get-ADGroupMember -Identity "Enterprise Admins" | Where-Object { $_.objectClass -eq 'user' }

# Loop through each member and retrieve their password expiration date
foreach ($member in $groupMembers) {
    $user = Get-ADUser -Identity $member.SamAccountName -Properties "DisplayName", "PasswordNeverExpires", "PasswordExpired", "PasswordLastSet", "msDS-UserPasswordExpiryTimeComputed"
    $displayName = $user.DisplayName
    $passwordNeverExpires = $user.PasswordNeverExpires
    $passwordExpired = $user.PasswordExpired

    # Calculate password expiration date
    if ($passwordNeverExpires -eq $true) {
        $expirationDate = "Password never expires"
    } elseif ($passwordExpired -eq $true) {
        $expirationDate = "Password has expired"
    } else {
        $lastSet = $user.PasswordLastSet
        $expiryTime = $user."msDS-UserPasswordExpiryTimeComputed"
        $expirationDate = $lastSet + [timespan]::FromTicks($expiryTime)
    }

    # Output the member's display name and password expiration date
    Write-Output "Member: $displayName"
    Write-Output "Password Expiration Date: $expirationDate"
    Write-Output "--------------------------"
}