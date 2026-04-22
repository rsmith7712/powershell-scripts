# BackPressure.ps1

PowerShell script for checking Microsoft Exchange transport servers for back pressure events in the Application log.

## Overview

This repository contains a cleaned and public-safe version of a legacy Exchange monitoring script, plus a modernized v2 variant.

- `BackPressure.Public.ps1` preserves the original legacy approach with minimal cleanup.
- `BackPressure.v2.ps1` modernizes the script with clearer parameters, safer object handling, `Get-WinEvent`, and optional CSV export.

## What it does

The script checks one Exchange server or a set of Exchange servers for transport back pressure events and reports whether a back pressure condition was detected, what state it was in, and when the most recent event occurred.

## Intended environment

- Windows PowerShell 5.1 or later for `BackPressure.v2.ps1`
- Exchange 2010 management tools or Exchange Management Shell access
- Remote PowerShell / WinRM access to target Exchange servers
- Permissions to read the remote Application event log

## Why this script exists

Back pressure is Exchange transport self-protection behavior that can occur when system resources such as disk space or memory become constrained. This script provides a fast way to check affected servers and summarize the most recent condition.

## Usage

### Check all Hub Transport servers

```powershell
.\BackPressure.v2.ps1
```

### Check a specific server

```powershell
.\BackPressure.v2.ps1 -Server EXAMPLE-EX01
```

### Check multiple servers and export a report

```powershell
.\BackPressure.v2.ps1 -Server EXAMPLE-EX01,EXAMPLE-EX02 -ReportPath .\Reports\BackPressureReport.csv
```

### Include the last event message in the output object

```powershell
.\BackPressure.v2.ps1 -IncludeEventDetails
```

## Parameters

| Parameter | Description |
|---|---|
| `-Server` | One or more Exchange server names. If omitted, the script queries all Hub Transport servers it can discover. |
| `-Role` | Role filter. Defaults to `HubTransport`. Accepts `All` to query all Exchange servers returned by `Get-ExchangeServer`. |
| `-MaxEvents` | Maximum number of matching events to retrieve from each server. Default is `200`. |
| `-ReportPath` | Optional CSV output path. |
| `-IncludeEventDetails` | Includes the last event message in the result object. |

## Notes

- This script is intended for legacy Exchange environments that still expose the Exchange 2010 management snap-in.
- `BackPressure.v2.ps1` uses `Get-WinEvent` instead of `Get-EventLog`.
- The original public-safe script was cleaned to remove malformed dash characters and genericize example values.

## Public posting guidance

Before publishing scripts like this to GitHub, remove or replace:

- internal server names
- internal email addresses or support contacts
- company-specific URLs
- personal author metadata you do not want publicly exposed
- any environment-specific comments that reveal topology or naming standards

## License

This repository is provided under the MIT License. See `LICENSE`.
