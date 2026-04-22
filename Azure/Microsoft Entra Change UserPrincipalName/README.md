# Change-M365UserPrincipalName

Simple PowerShell sample for changing a Microsoft 365 user's User Principal Name (UPN) by using the legacy **MSOnline** module.

## What it does

This script:
- prompts for administrator credentials
- connects to Microsoft 365 with `Connect-MsolService`
- changes a user's sign-in name with `Set-MsolUserPrincipalName`

## Important notes

- This repository is a **legacy sample**. The MSOnline module is older administrative tooling.
- Test first with a non-production account.
- If the account is synchronized from on-premises Active Directory, update the on-premises UPN first and let directory sync flow the change.
- Confirm the target domain is already verified in the tenant before changing the UPN.

## Requirements

- Windows PowerShell 5.1
- MSOnline module installed
- Administrative permissions to update users in Microsoft 365 / Microsoft Entra ID

## Usage

```powershell
$cred = Get-Credential
Connect-MsolService -Credential $cred
Set-MsolUserPrincipalName -UserPrincipalName oldname@example.com -NewUserPrincipalName newname@example.com
```

Or run the sample script:

```powershell
.\Change-M365UserPrincipalName.Public.ps1 -CurrentUserPrincipalName oldname@example.com -NewUserPrincipalName newname@example.com
```

## Public-safe placeholders

Replace environment-specific values with placeholders such as:
- `oldname@example.com`
- `newname@example.com`
- `EXAMPLE-TENANT.onmicrosoft.com`
- `example.com`

## Safer modernization path

For newer environments, move this workflow to Microsoft Graph PowerShell and add:
- pre-change validation
- CSV-driven bulk mode
- logging and transcript output
- `-WhatIf` support
- sync-awareness for hybrid identities

## License

Released under the MIT License.
