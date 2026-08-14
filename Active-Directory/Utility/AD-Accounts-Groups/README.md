# AD Password Expiry Notice

PowerShell script for on-premises Active Directory environments that identifies users whose passwords are nearing expiration and sends them an HTML reminder email.

## Highlights

- Uses the domain's default password policy to calculate expiry dates
- Filters out disabled users, expired accounts, password-never-expires accounts, and users without email addresses
- Supports test targeting of a single user
- Supports `-WhatIf`, `-Confirm`, and `-PreviewOnly`
- Exports a CSV report for each run
- Uses public-safe placeholder values so the repo can be published safely

## Files

```text
.
├── AD-PasswordExpiryNotice.v2.ps1
├── README.md
├── .gitignore
├── LICENSE
└── CHANGELOG.md
```

## Requirements

- Windows PowerShell 5.1
- RSAT / Active Directory module
- Network access to an SMTP relay
- Permission to query user objects in Active Directory

## What the script does

1. Imports the Active Directory module
2. Reads the domain default password policy
3. Queries user accounts from Active Directory
4. Calculates each eligible user's password expiration date
5. Selects users within the reminder window
6. Sends reminder emails or performs a preview / WhatIf run
7. Writes a CSV report of the outcome

## Quick start

Run a safe preview first:

```powershell
.\AD-PasswordExpiryNotice.v2.ps1 -PreviewOnly -Verbose
```

Run against a single test user:

```powershell
.\AD-PasswordExpiryNotice.v2.ps1 -TestingUsername test.user -PreviewOnly -Verbose
```

Send emails for real:

```powershell
.\AD-PasswordExpiryNotice.v2.ps1 `
  -From 'it-support@example.com' `
  -SmtpServer 'smtp.example.com' `
  -SmtpPort 587 `
  -UseSsl `
  -MailSubject 'Important Reminder: Your password will expire soon' `
  -DaysBeforeExpiry 5 `
  -CompanyName 'Example Company' `
  -PortalUrl 'https://mail.example.com' `
  -ServiceDeskEmail 'it-support@example.com' `
  -ServiceDeskPhone '555-0100' `
  -ReportPath '.\Logs\PasswordExpiryReport.csv' `
  -Verbose
```

Simulate a send without sending mail:

```powershell
.\AD-PasswordExpiryNotice.v2.ps1 -WhatIf
```

## Parameters

| Parameter | Purpose |
|---|---|
| `From` | Sender email address |
| `SmtpServer` | SMTP relay hostname |
| `SmtpPort` | SMTP port, default `587` |
| `UseSsl` | Enables SSL/TLS |
| `SmtpCredential` | Optional SMTP credential |
| `MailSubject` | Subject line for reminder email |
| `DaysBeforeExpiry` | Reminder window in days |
| `PreviewOnly` | Builds results without sending email |
| `TestingUsername` | Targets a single user for validation |
| `SearchBase` | Optional OU / DN scope |
| `CompanyName` | Company name used in the email body |
| `PortalUrl` | Webmail or self-service password portal |
| `ServiceDeskEmail` | Support mailbox shown in the email |
| `ServiceDeskPhone` | Support phone shown in the email |
| `ReportPath` | CSV output path |

## Public-safe placeholders to replace

| Placeholder | Replace with |
|---|---|
| `it-support@example.com` | Your sender and service desk mailbox |
| `smtp.example.com` | Your SMTP relay |
| `https://mail.example.com` | Your webmail or password-change portal |
| `555-0100` | Your service desk phone number |
| `Example Company` | Your organization name |
| `test.user` | A valid test account |

## Notes

- This script uses the domain **default** password policy. If your environment uses Fine-Grained Password Policies, the calculated expiration date may not be correct for every user.
- `System.Net.Mail.SmtpClient` is used for broad Windows PowerShell compatibility. For Microsoft 365 or internet-facing delivery, many teams prefer a more modern mail transport pattern such as Microsoft Graph or MailKit.
- Publish the repository using the public-safe placeholders only. Do not commit internal SMTP servers, helpdesk addresses, personal names, internal URLs, or test account names.

## Suggested .gitignore scope

The included `.gitignore` is intentionally practical for PowerShell repositories. It excludes:

- editor and IDE folders
- logs and transcripts
- generated reports
- temporary files
- secrets and local overrides
- module packaging output

## License

MIT
