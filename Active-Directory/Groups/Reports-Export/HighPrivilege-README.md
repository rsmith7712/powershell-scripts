# Public-Safe AD Admin Group Membership Report

PowerShell scripts that export membership for selected Active Directory administrative groups in either text/PDF format or combined TXT/PDF and CSV formats.

This repository is a **public-safe redacted version** intended for GitHub posting. It replaces environment-specific details with placeholders and documents the tradeoffs around PDF generation and privileged group reporting.

## What the script does

- Imports the **ActiveDirectory** PowerShell module
- Queries one or more AD groups, such as `Domain Admins`, `Enterprise Admins`, and `Schema Admins`
- Writes a timestamped text report to a chosen output folder
- Optionally converts the text report to PDF by automating Microsoft Word
- Includes a second script that writes both human-readable TXT/PDF output and structured CSV output

## Why this version is safer to publish

The original pattern often includes items that should not be posted publicly without review, such as:

- personal attribution or internal ownership details
- privileged group names that are specific to a production environment
- hard-coded local or network paths
- assumptions that Microsoft Word is installed

This version:

- uses configurable parameters instead of fixed paths
- keeps group names configurable through `-GroupNames`
- uses a generic output directory (`C:\Reports`) by default
- clearly labels Word-based PDF conversion as optional

## Requirements

- Windows PowerShell 5.1 or PowerShell 7+
- RSAT Active Directory module or equivalent AD cmdlets available
- permission to query the target groups
- Microsoft Word installed **only if** using `-ConvertToPdf`

## Usage

### Basic text report

```powershell
.\scripts\Export-ADAdminGroupMembership.ps1
```

### Multi-format report: TXT + CSV

```powershell
.\scripts\Export-ADAdminGroupMembership-MultiFormat.ps1
```

### Custom output path

```powershell
.\scripts\Export-ADAdminGroupMembership.ps1 -OutputDirectory 'C:\Reports\AD'
```

### Custom groups

```powershell
.\scripts\Export-ADAdminGroupMembership.ps1 -GroupNames 'Domain Admins','Server Operators','Backup Operators'
```

### Generate PDF

```powershell
.\scripts\Export-ADAdminGroupMembership.ps1 -ConvertToPdf
```

### Generate TXT, CSV, and PDF together

```powershell
.\scripts\Export-ADAdminGroupMembership-MultiFormat.ps1 -ConvertToPdf
```

## Recommended placeholder values for public posts

Replace environment-specific items with placeholders such as:

- `Richard Smith` -> `<Your Name>` or `<Organization Name>`
- `E:\ScriptOut\` -> `C:\Reports\` or `<OutputDirectory>`
- `Domain Admins` -> `<PrivilegedGroup1>` when showing examples outside production context
- `Enterprise Admins` -> `<PrivilegedGroup2>`
- `Schema Admins` -> `<PrivilegedGroup3>`

If you are documenting real privileged groups for internal use, keep that version private.

## Notes on PDF conversion

The `-ConvertToPdf` option uses the Microsoft Word COM object. That means:

- it is Windows-specific
- Word must be installed locally
- COM automation may not be appropriate for server-side or unattended execution

For automation-heavy environments, consider keeping the text output only, or replacing Word automation with a different document-generation workflow.

## Repository contents

- `scripts/Export-ADAdminGroupMembership.ps1` - text report with optional PDF conversion
- `scripts/Export-ADAdminGroupMembership-MultiFormat.ps1` - TXT/PDF plus CSV export variant
- `README.md` - project overview and usage
- `.gitignore` - PowerShell-focused ignore rules
- `LICENSE` - MIT license
- `CHANGELOG.md` - concise change history

## License

Released under the MIT License. See `LICENSE` for details.
