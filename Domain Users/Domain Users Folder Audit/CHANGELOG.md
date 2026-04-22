# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project uses a simple date-based release notation for this public-safe starter version.

## [2026.04.22] - 2026-04-22

### Added
- Initial public-safe repository structure
- GitHub-ready `README.md`
- PowerShell-oriented `.gitignore`
- MIT `LICENSE`
- `CHANGELOG.md`
- Sanitized `scripts/FolderAudit.ps1`

### Changed
- Rewrote script comments so they accurately describe folder auditing and optional stale-folder purge behavior
- Replaced environment-specific values with placeholders suitable for public posting
- Refactored result creation to use a fresh `PSCustomObject` per folder
- Improved parameter names and in-script documentation for clarity
- Added `SupportsShouldProcess` support for safer purge preview using `-WhatIf`
- Corrected the deletion error log filename to `remove_item_errors.txt`

### Security
- Removed internal naming conventions from the public version
- Replaced hard-coded domain and file share details with generic placeholders
- Added repository guidance encouraging testing and review before enabling destructive actions
