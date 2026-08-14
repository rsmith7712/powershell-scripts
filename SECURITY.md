# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this repository, please report it
**privately** rather than opening a public issue.

- **Contact:** `16009449+rsmith7712@users.noreply.github.com`
- Please include: a description of the issue, steps to reproduce, the affected
  script(s)/path(s), and any suggested remediation.
- You can expect an initial acknowledgement within a reasonable timeframe, and an
  update once the report has been reviewed.

Please do **not** disclose the issue publicly until it has been reviewed and addressed.

## Scope and Caveats

This repository is an archive of PowerShell / batch administration scripts,
published **"as is"** under the [MIT License](LICENSE). Note:

- Scripts may contain environment-specific paths, hostnames, and placeholders that
  have been **genericized/obfuscated for publication** (e.g. `\\SERVER\SHARE\...`,
  `C:\temp\`, `UFO_NUMBER`, `Application-Key-Here`). Validate and adapt them for your
  own environment before use.
- Any credentials that previously appeared in history were removed and rotated;
  do not assume placeholder values are functional secrets.
- Review each script before running it in a production environment.
