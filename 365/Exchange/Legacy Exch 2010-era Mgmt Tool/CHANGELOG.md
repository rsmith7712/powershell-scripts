# Changelog

All notable changes to this project are documented in this file.

## [2.0.0] - 2026-04-22
### Added
- Modernized `BackPressure.v2.ps1` using `Get-WinEvent`
- Optional CSV reporting via `-ReportPath`
- Optional event message inclusion with `-IncludeEventDetails`
- Clearer parameter handling for single or multiple target servers

### Changed
- Replaced malformed dash characters in command syntax
- Improved server object handling and result formatting
- Genericized examples and documentation for safe public posting

## [1.0.0] - 2026-04-22
### Added
- Public-safe legacy script package based on the original Exchange 2010 script
