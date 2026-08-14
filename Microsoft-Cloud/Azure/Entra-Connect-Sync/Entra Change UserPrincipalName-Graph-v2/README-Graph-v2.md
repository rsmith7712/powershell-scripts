# Change-M365UserPrincipalName

Simple PowerShell script that updates a Microsoft 365 user's User Principal Name (UPN) by using Microsoft Graph PowerShell.

## Overview

This script:

- prompts for a current UPN and a new UPN through parameters
- connects to Microsoft Graph
- retrieves the target user
- updates the user's `userPrincipalName`
- optionally returns the updated object for logging or pipeline use

## Why this version

This repository provides a modern replacement for legacy `MSOnline` / `Set-MsolUserPrincipalName` snippets. Microsoft states that the Azure AD and MSOnline PowerShell modules were deprecated on March 30, 2024, with limited support thereafter, and recommends Microsoft Graph PowerShell for new development.

## Requirements

- PowerShell 5.1 or later
- Microsoft Graph PowerShell SDK
- An account allowed to update users in Microsoft Entra ID
- Delegated Graph scope: `User.ReadWrite.All`

Install the SDK if needed:

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
```

## Usage

### Basic example

```powershell
.\Change-M365UserPrincipalName-Graph-v2.ps1 `
  -CurrentUserPrincipalName old.user@example.com `
  -NewUserPrincipalName new.user@example.com
```

### Preview the change

```powershell
.\Change-M365UserPrincipalName-Graph-v2.ps1 `
  -CurrentUserPrincipalName old.user@example.com `
  -NewUserPrincipalName new.user@example.com `
  -WhatIf
```

### Return an object after the update

```powershell
.\Change-M365UserPrincipalName-Graph-v2.ps1 `
  -CurrentUserPrincipalName old.user@example.com `
  -NewUserPrincipalName new.user@example.com `
  -PassThru
```

## Notes

- For hybrid-synced accounts, update the on-premises Active Directory UPN first, then allow sync to update the cloud object.
- The script uses `ShouldProcess`, so `-WhatIf` and `-Confirm` are supported.
- Replace all example domains with your own tenant values before use.

## Public-safe placeholders

Use placeholders like these in docs and examples:

- `old.user@example.com`
- `new.user@example.com`
- `admin@example.com`
- `tenantname.onmicrosoft.com`

Avoid publishing:

- real employee aliases
- admin naming conventions
- production tenant domains
- screenshots showing tenant IDs or user object IDs

## Security and operational considerations

Before changing a UPN:

- confirm the target domain is verified in your tenant
- confirm the account is cloud-only or understand hybrid sync behavior
- review downstream dependencies that might reference the current sign-in name
- prefer object IDs in automation where identity stability matters

## License

MIT
