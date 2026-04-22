# Public-Safe AD Group Reports

A GitHub-ready, sanitized PowerShell example for exporting Active Directory group membership and AD group inventory reports.

This repository is designed for **public sharing**. Internal names, output paths, and organization-specific identifiers have been replaced with safe placeholders.

## What the script does

`ADGroupReports.ps1` can export:

- members of a specified AD group
- a name-focused inventory of all AD groups
- an optional full-property AD group inventory
- both CSV and CLI XML output where useful

## Why this version is safer for GitHub

The original snippet had a few issues common in internal admin scripts:

- CSV filenames were used with `Out-File`, which does **not** create structured CSV data
- some comments implied “distribution groups,” but the commands actually queried **all AD groups**
- hard-coded output paths such as `C:\...` may be fine internally but are better parameterized publicly
- full-property exports can expose more directory metadata than intended

This public-safe version corrects those issues and documents the tradeoffs.

## Repository structure

```text
public-safe-ad-group-report/
├── .gitignore
├── CHANGELOG.md
├── LICENSE
├── README.md
└── scripts/
    └── ADGroupReports.ps1
```

## Requirements

- Windows PowerShell 5.1 or PowerShell 7+
- RSAT Active Directory module, or another environment where the `ActiveDirectory` module is available
- Permissions to query Active Directory

## Usage

Run with defaults:

```powershell
.\scripts\ADGroupReports.ps1
```

Export a different group:

```powershell
.\scripts\ADGroupReports.ps1 -TargetGroup 'Domain Admins'
```

Write reports to a different folder:

```powershell
.\scripts\ADGroupReports.ps1 -OutputDirectory 'C:\Reports'
```

Also export the full AD group inventory:

```powershell
.\scripts\ADGroupReports.ps1 -IncludeFullGroupInventory
```

## Output files

Typical outputs include:

- `AD_GroupMembers.csv`
- `AD_GroupMembers.xml`
- `AD_Groups_NameOnly.csv`
- `AD_Groups_NameOnly.txt`
- `AD_Groups_FullInventory.csv` (optional)

## Public-safe placeholders

Before using this in a real environment, review and replace placeholders as needed:

| Placeholder | Purpose | Example replacement |
|---|---|---|
| `Administrators` | Default group queried for membership | `Domain Admins` |
| `C:\Reports` | Output directory | `C:\Temp\ADReports` |
| `<YOUR NAME OR ORGANIZATION>` | License attribution | `Jane Doe` or `Contoso Ltd.` |

## Notes on “distribution groups”

The original script labeled some outputs as distribution group reports, but `Get-ADGroup -Filter *` returns **all AD groups**, not just mail-enabled distribution groups.

If you truly need mail distribution groups, use a method appropriate to your environment, such as:

- Exchange cmdlets for distribution groups
- filtering against known Exchange-related attributes after validating your schema and usage

## Safety and privacy notes

Before posting AD-related scripts publicly:

- remove internal OU paths, domain names, and server names
- avoid publishing real group names tied to privileged roles unless necessary
- be cautious with `-Properties *`, since it can expose more metadata than intended
- prefer parameterized paths instead of hard-coded internal directories
- keep sample data generic

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
