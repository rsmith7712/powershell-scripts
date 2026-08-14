# Get-DNSServers.ps1

GitHub-safe PowerShell script for querying DNS server settings from IP-enabled network adapters on local or remote Windows computers.

## What it does

- Accepts one or more computer names
- Tests basic connectivity
- Queries `Win32_NetworkAdapterConfiguration`
- Returns:
  - computer name
  - primary DNS server
  - secondary DNS server
  - DHCP enabled state
  - adapter description
  - full DNS server list

## Why this version is safer to publish

This version removes or replaces:

- personal author details
- organization-specific identifiers
- internal naming conventions
- editor metadata
- older object-construction style

It also modernizes the script to use `Get-CimInstance` instead of legacy `Get-WmiObject`.

## Usage

Run against the local computer:

```powershell
.\Get-DNSServers.ps1
```

Run against a single remote computer:

```powershell
.\Get-DNSServers.ps1 -ComputerName SERVER01
```

Run against multiple computers:

```powershell
.\Get-DNSServers.ps1 -ComputerName SERVER01,SERVER02,SERVER03
```

Pipeline input:

```powershell
'SERVER01','SERVER02' | .\Get-DNSServers.ps1
```

Verbose output:

```powershell
.\Get-DNSServers.ps1 -ComputerName SERVER01 -Verbose
```

Export results:

```powershell
.\Get-DNSServers.ps1 -ComputerName SERVER01,SERVER02 | Export-Csv .\DnsResults.csv -NoTypeInformation
```

## Notes

- Remote CIM access may require firewall rules, permissions, and WinRM/DCOM configuration depending on the environment.
- The script reports only the first two DNS servers as primary and secondary, but also includes `AllDNSServers`.
- If a host is unreachable, the script skips it and continues.

## Example output

```text
ComputerName PrimaryDNSServer SecondaryDNSServer IsDHCPEnabled NetworkName                  AllDNSServers
------------ ---------------- ------------------ ------------- -----------                  -------------
SERVER01     10.0.0.10        10.0.0.11          False         Intel(R) Ethernet Adapter   10.0.0.10, 10.0.0.11
```

## Repository contents

```text
.
├── Get-DNSServers.ps1
├── README.md
├── CHANGELOG.md
├── LICENSE
└── .gitignore
```

## Security guidance

Do not add real internal values to public repositories, including:

- real hostnames
- domain names
- internal IP addresses
- user names
- organization names
- internal comments
- support URLs
- asset naming conventions

Use placeholder values such as:

- `SERVER01`
- `Example Corp.`
- `<Author Name>`
- `<YYYY-MM-DD>`
