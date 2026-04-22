# Changelog

All notable changes to this public-safe version will be documented in this file.

## 1.0.0 - 2026-04-22

- created a public-safe redacted version of the original script
- replaced hard-coded output paths with configurable parameters
- made target group names configurable through `-GroupNames`
- corrected comments and help text to match actual script behavior
- made PDF conversion optional through `-ConvertToPdf`
- added basic error handling for AD group queries
- added GitHub-ready repository scaffolding: `README.md`, `.gitignore`, `LICENSE`, and `CHANGELOG.md`

## [1.1.0] - 2026-04-22
### Added
- Added `Export-ADAdminGroupMembership-MultiFormat.ps1` to generate TXT, CSV, and optional PDF output in one run.
- Expanded the README with multi-format usage examples and repository contents.

### Changed
- Clarified that the repository now includes both a text/PDF-focused script and a multi-format reporting variant.
