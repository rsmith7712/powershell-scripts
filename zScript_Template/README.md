# Enterprise PowerShell Template

GitHub-safe, enterprise reusable PowerShell template with comment-based help, parameter validation, transcript logging, local log files, optional remote logging, prerequisite checks, and `SupportsShouldProcess`.

## What is included

- `Invoke-EnterpriseTemplate.ps1`
- `.gitignore`
- `LICENSE`
- `CHANGELOG.md`

## Features

- Comment-based help
- Parameter validation
- Admin elevation support
- Transcript logging
- Local log and action tracking
- Optional remote logging stub
- Structured error handling
- `-WhatIf` support through `SupportsShouldProcess`

## Files

### `Invoke-EnterpriseTemplate.ps1`
Reusable starter script for enterprise automation.

### `.gitignore`
Prevents logs, transcripts, and editor artifacts from being committed.

### `CHANGELOG.md`
Starter changelog following a simple semantic versioning pattern.

### `LICENSE`
MIT License template.

## Usage

Run normally:

```powershell
.\Invoke-EnterpriseTemplate.ps1
```

Run with transcript logging:

```powershell
.\Invoke-EnterpriseTemplate.ps1 -EnableTranscript
```

Run with `-WhatIf`:

```powershell
.\Invoke-EnterpriseTemplate.ps1 -WhatIf
```

Specify a custom log root:

```powershell
.\Invoke-EnterpriseTemplate.ps1 -LogRoot "C:\ProgramData\Company\Logs"
```

Enable remote logging with placeholder values replaced:

```powershell
.\Invoke-EnterpriseTemplate.ps1 `
  -EnableRemoteLogging `
  -RemoteLogUri "https://logging.example.com/services/collector/event" `
  -RemoteLogToken "<TOKEN>"
```

## Security guidance

Do not publish real values for:

- logging endpoints
- API tokens
- internal hostnames
- internal product names
- tenant names
- usernames
- environment-specific paths

Use a secret store for production values, such as:

- environment variables
- Windows Credential Manager
- Azure Key Vault
- GitHub Actions secrets
- CI/CD platform secret stores

## Recommended next steps

Customize:

- script name
- product naming
- prerequisite tests
- main execution logic
- remote logging format
- log retention and cleanup behavior

## Example repository structure

```text
.
├── Invoke-EnterpriseTemplate.ps1
├── README.md
├── CHANGELOG.md
├── LICENSE
└── .gitignore
```

## Notes

This starter intentionally uses placeholder values for anything
environment-specific so it can be posted publicly with reduced
risk.
