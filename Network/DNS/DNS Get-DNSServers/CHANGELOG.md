# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-04-22
### Added
- Initial GitHub-safe release of `Get-DNSServers.ps1`
- Comment-based help
- Modernized CIM query logic
- README, LICENSE, `.gitignore`, and changelog

### Changed
- Replaced legacy `Get-WmiObject` usage with `Get-CimInstance`
- Replaced older object construction with `[pscustomobject]`
- Added `AllDNSServers` output field
- Fixed DHCP state handling
