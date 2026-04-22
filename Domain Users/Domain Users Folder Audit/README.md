# Public-Safe Folder Audit

A GitHub-ready, public-safe PowerShell script for auditing folders beneath a target directory and, if explicitly enabled, purging stale folders.

This repository is a **sanitized example** intended for public sharing. Environment-specific details such as internal server names, domain names, administrative groups, and personal identifiers have been replaced with placeholders.

## Features

- Enumerates subfolders under a target path
- Records folder name, inferred owner(s), last accessed time, and last written time
- Optionally calculates recursive folder size
- Optionally purges stale folders that appear orphaned and inactive
- Exports results to CSV
- Supports `-WhatIf` and `-Confirm` for safer testing of destructive actions

## Repository Structure

```text
public-safe-folder-audit/
├── .gitignore
├── CHANGELOG.md
├── LICENSE
├── README.md
└── scripts/
    └── FolderAudit.ps1
```

## Script Summary

`FolderAudit.ps1` scans immediate child folders beneath a target path and exports results to a CSV file. When purge mode is enabled, it attempts to remove folders only when they meet all configured stale-folder conditions.

Captured fields include:

- `Folder_Name`
- `User`
- `Last_Accessed`
- `Last_Written`
- `Size` (optional)
- `Folders_Purged` (when purge mode is used)

## Public-Safe Placeholders

Before using this script in a real environment, replace the following placeholders:

| Placeholder | Purpose | Example replacement |
|---|---|---|
| `\\FileServer\Shares\UserHomeDirs` | Default target path | `\\FS01\Shares\UserHomeDirs` |
| `EXAMPLE\Domain Admins` | Administrative group used for ownership recovery | `CONTOSO\Domain Admins` |
| `<YOUR NAME OR ORGANIZATION>` | Copyright / attribution | `Jane Doe` or `Contoso Ltd.` |

## Requirements

- Windows PowerShell 5.1 or PowerShell 7+
- Permissions to read the target folders
- Administrative privileges if ownership recovery and deletion are required

## Usage

Run with the default path:

```powershell
.\scripts\FolderAudit.ps1
```

Run and include folder sizes:

```powershell
.\scripts\FolderAudit.ps1 -GetSize
```

Prompt for a path interactively:

```powershell
.\scripts\FolderAudit.ps1 -UsePromptForPath
```

Preview purge behavior without deleting anything:

```powershell
.\scripts\FolderAudit.ps1 -PurgeStaleFolders -WhatIf
```

Run purge with confirmation prompts:

```powershell
.\scripts\FolderAudit.ps1 -PurgeStaleFolders -Confirm
```

Override the default path and output file:

```powershell
.\scripts\FolderAudit.ps1 \
  -DefaultPath "\\FileServer\Shares\UserHomeDirs" \
  -OutputPath "$env:USERPROFILE\Documents\folder-audit-results.csv"
```

## Parameters

| Parameter | Type | Description |
|---|---|---|
| `-GetSize` | Switch | Calculates recursive folder size |
| `-UsePromptForPath` | Switch | Prompts for a target path instead of using `DefaultPath` |
| `-PurgeStaleFolders` | Switch | Removes folders that match the stale-folder criteria |
| `-DefaultPath` | String | Default root path containing folders to inspect |
| `-OutputPath` | String | CSV output path |
| `-ErrorLogPath` | String | Path used for deletion error logging |
| `-AdminGroup` | String | Administrative group granted access if ownership recovery is needed |
| `-StaleYears` | Int | Number of years used to determine whether a folder is stale |

## Safety Notes

This script can perform recursive deletion when `-PurgeStaleFolders` is enabled.

Use it responsibly:

1. Test with `-WhatIf` first.
2. Validate stale-folder criteria in a non-production location.
3. Review `LastAccessTime` behavior in your environment before relying on it.
4. Confirm the placeholder admin group and default path are updated before production use.
5. Consider adding centralized logging, code signing, and access review controls for enterprise use.

## Recommended Production Hardening

Before production deployment, consider:

- replacing placeholders with environment-specific values
- writing results and logs to a controlled location
- adding transcript or structured logging
- adding exclusion lists for service, legal hold, or VIP folders
- integrating notification or approval workflow before deletion
- digitally signing the script

## Disclaimer

This repository is provided as an example and starter template. Review, test, and adapt it for your own environment before operational use.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
