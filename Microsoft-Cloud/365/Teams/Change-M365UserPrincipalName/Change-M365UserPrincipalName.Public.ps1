# Requires -Modules MSOnline
# LEGAL
<# LICENSE
    MIT License, Copyright 2017 Richard Smith

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
    Change-M365UserPrincipalName.Public.ps1

.SYNOPSIS
    Change a Microsoft 365 user's User Principal Name (UPN).

.DESCRIPTION
    Prompts for credentials, connects to the legacy MSOnline module,
    and updates a user's sign-in name from one UPN to another.

.NOTES
    This sample uses the legacy MSOnline module for compatibility with older environments.
    For newer automation, consider Microsoft Graph PowerShell.

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$CurrentUserPrincipalName,

    [Parameter(Mandatory = $true)]
    [string]$NewUserPrincipalName
)

$Credential = Get-Credential
Connect-MsolService -Credential $Credential
Set-MsolUserPrincipalName -UserPrincipalName $CurrentUserPrincipalName -NewUserPrincipalName $NewUserPrincipalName
