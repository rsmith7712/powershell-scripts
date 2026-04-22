# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-04-22
### Added
- Public-safe PowerShell script for AD group membership and group inventory reporting.
- GitHub-ready README, MIT LICENSE, PowerShell-focused `.gitignore`, and concise changelog.

### Changed
- Replaced `Out-File`-based pseudo-CSV output with proper `Export-Csv` usage.
- Replaced hard-coded assumptions with parameters and public-safe placeholders.
- Corrected comments so they align with the script’s actual behavior.

### Notes
- The script queries Active Directory groups broadly; it does not inherently identify Exchange distribution groups.
