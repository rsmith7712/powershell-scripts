# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0] - 2026-04-22
### Added
- Parameterized public-safe script for GitHub publication
- `-PreviewOnly`, `-WhatIf`, and `-Confirm` support
- CSV reporting with configurable output path
- Optional SMTP credential, port, and SSL/TLS settings
- Optional `SearchBase` scoping and single-user testing mode

### Changed
- Replaced hard-coded organization-specific values with generic placeholders
- Improved filtering for disabled users, missing email addresses, and non-expiring passwords
- Improved error handling and verbose logging
- Refreshed README, LICENSE, and repository packaging for public release

## [1.0.0] - 2016-10-24
### Added
- Initial internal script to notify AD users of upcoming password expiration
