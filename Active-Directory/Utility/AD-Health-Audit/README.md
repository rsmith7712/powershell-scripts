# AD Health Quick Check (Public-Safe Example)

A small PowerShell example for performing a quick Active Directory health spot-check against a domain controller.

This public-safe version is intended for GitHub sharing. It removes environment-specific values, uses placeholders, and documents the script's scope clearly.

## What it does

The script performs a short set of AD checks:

- runs `repadmin /replsum` to summarize replication health
- checks a target server for a small set of critical AD-related services
- runs `dcdiag /test:DNS`
- looks for LDAP-related event IDs associated with signing and insecure bind visibility
- writes a transcript report to disk

## What it does not do

This is not a full enterprise AD assessment. It is a quick operational spot-check.

## Requirements

- Windows PowerShell 5.1 or PowerShell 7 with compatible tooling
- RSAT / Active Directory PowerShell module
- `repadmin` and `dcdiag` available on the host
- Administrative privileges
- Network access to the target domain controller

## Usage

```powershell
.\scripts\Test-ADHealthQuickCheck.ps1 -Server DC01 -OutputDirectory C:\Reports
```


## Included scripts

- `scripts/Test-ADHealthQuickCheck.ps1` - console-first quick check with transcript output
- `scripts/Test-ADHealthQuickCheck-Reports.ps1` - reporting-focused version that exports transcript, CSV, and HTML

## Reporting version usage

```powershell
.\scripts\Test-ADHealthQuickCheck-Reports.ps1 -Server DC01 -OutputDirectory C:\Reports
```

### Reporting outputs

The reporting-focused script writes:

- a transcript `.txt` file
- a service-status `.csv` file
- an LDAP-related events `.csv` file
- an `.html` summary report that includes service results, event findings, and captured command output

## Public-safe placeholders

Before using in a real environment, replace sample values such as:

- `DC01` → your actual domain controller hostname
- `C:\Reports` → your preferred output directory

## Notes on the original script

The original script used a placeholder server value and mixed friendly display names with service names. In Windows service queries, using actual service names is more reliable.

Examples used in this repo:

- `DNS`
- `DFSR`
- `IsmServ`
- `Kdc`
- `Netlogon`
- `NTDS`

## Safety considerations

Do not publish:

- real domain controller names
- internal domain names
- actual output paths that reveal internal standards unnecessarily
- screenshots or outputs that expose replication partners, site names, naming conventions, or account details

## License

This repository uses the MIT License.
