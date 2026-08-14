[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[^@\s]+@[^@\s]+\.[^@\s]+$')]
    [string]$CurrentUserPrincipalName,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[^@\s]+@[^@\s]+\.[^@\s]+$')]
    [string]$NewUserPrincipalName,

    [switch]$PassThru
)
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
    Change-M365UserPrincipalName-Graph-v2.ps1

.SYNOPSIS
    Updates a Microsoft 365 user's User Principal Name (UPN) by using Microsoft Graph PowerShell.

.DESCRIPTION
    Connects to Microsoft Graph with the minimum delegated scope needed to update a user,
    retrieves the target user by current UPN, validates the lookup, and updates the user's
    userPrincipalName to the new value.

    .NOTES
    Requirements:
    - PowerShell 5.1 or later
    - Microsoft Graph PowerShell SDK
    - Permission scope: User.ReadWrite.All
    - Best suited for cloud-only accounts. For hybrid-synced users, change the on-premises UPN
      first and allow sync to update Microsoft 365.

    Important note: Microsoft states the Azure AD and MSOnline PowerShell modules were
    deprecated on March 30, 2024, with limited support afterward, and recommends Microsoft
    Graph PowerShell for new development.

    Recommended example:
    .\Change-M365UserPrincipalName-Graph-v2.ps1 `
        -CurrentUserPrincipalName old.user@example.com `
        -NewUserPrincipalName new.user@example.com `
        -WhatIf

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

#>

$requiredModule = 'Microsoft.Graph.Users'

try {
    if (-not (Get-Module -ListAvailable -Name $requiredModule)) {
        throw "Required module '$requiredModule' is not installed. Install it with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }

    Import-Module $requiredModule -ErrorAction Stop

    Write-Verbose "Connecting to Microsoft Graph..."
    Connect-MgGraph -Scopes 'User.ReadWrite.All' -NoWelcome -ErrorAction Stop | Out-Null

    Write-Verbose "Retrieving user '$CurrentUserPrincipalName'..."
    $user = Get-MgUser -UserId $CurrentUserPrincipalName -Property Id,DisplayName,UserPrincipalName -ErrorAction Stop

    if (-not $user) {
        throw "User '$CurrentUserPrincipalName' was not found."
    }

    $targetDescription = "$($user.DisplayName) <$($user.UserPrincipalName)>"

    if ($PSCmdlet.ShouldProcess($targetDescription, "Change UPN to '$NewUserPrincipalName'")) {
        Update-MgUser -UserId $user.Id -UserPrincipalName $NewUserPrincipalName -ErrorAction Stop

        $updatedUser = Get-MgUser -UserId $user.Id -Property Id,DisplayName,UserPrincipalName -ErrorAction Stop

        Write-Host "UPN updated successfully: $($updatedUser.UserPrincipalName)" -ForegroundColor Green

        if ($PassThru) {
            [pscustomobject]@{
                Id          = $updatedUser.Id
                DisplayName = $updatedUser.DisplayName
                PreviousUPN = $CurrentUserPrincipalName
                UpdatedUPN  = $updatedUser.UserPrincipalName
                Timestamp   = (Get-Date).ToString('s')
            }
        }
    }
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
finally {
    if (Get-Command Disconnect-MgGraph -ErrorAction SilentlyContinue) {
        Disconnect-MgGraph | Out-Null
    }
}
