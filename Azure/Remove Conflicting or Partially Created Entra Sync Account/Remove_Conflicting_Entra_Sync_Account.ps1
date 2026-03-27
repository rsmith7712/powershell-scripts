# LEGAL
<# LICENSE
    MIT License, Copyright 2024 Richard Smith

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
  Remove_Conflicting_Entra_Sync_Account.ps1

.DESCRIPTION
    Script to remove conflicting or partially created Entra sync accounts.

.FUNCTIONALITY
    This script is designed to identify and remove any conflicting or partially
    created Entra sync accounts that may be causing issues with synchronization.
    It connects to Azure AD, retrieves the list of users, identifies the sync
    account, and purges it if necessary.

.NOTES
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts

#>

# Install AzureAD Module
#DEPRECATED -- Install-Module -Name AzureAD

# Import the Module
#DEPRECATED -- Import-Module AzureAD
Import-Module Microsoft.Graph.Users

# Connect to Azure AD
#DEPRECATED -- Connect-AzureAD
Connect-MgGraph

# Get all users
Get-MgUser

# Retrieve Deleted Users
#DEPRECATED -- Get-AzureADDeletedUser

# Identify the Sync Account
#DEPRECATED -- Get-AzureADDeletedUser | Where-Object { $_.UserPrincipalName -like "*<partial or full sync account name>*" }

# Purge the Deleted User: Once you have the ObjectId:
#DEPRECATED -- Remove-AzureADDeletedUser -ObjectId "<ObjectId-of-sync-account>"
