# Contributing

Thanks for your interest in contributing. This repository is an archive of
PowerShell and batch administration scripts published under the
[MIT License](LICENSE).

## How to contribute

1. **Fork** the repository and create a branch for your change
   (`feature/<short-name>` or `fix/<short-name>`).
2. Make your change in a focused, single-purpose commit set.
3. Open a **Pull Request** with a clear description of *what* changed and *why*.

## Guidelines

- **No secrets or private identifiers.** Do not commit passwords, API keys,
  tokens, certificates, real hostnames, internal UNC paths, or personal data.
  This archive has been genericized for publication — keep it that way by using
  neutral placeholders (e.g. `\\SERVER\SHARE\...`, `C:\temp\`,
  `Application-Key-Here`, `UFO_NUMBER`). See [SECURITY.md](SECURITY.md).
- **Script header.** New or substantially changed scripts should carry the
  repository's standard header block (MIT license notice + a `GENERAL SCRIPT
  INFORMATION` block with purpose, author, and usage), matching the existing
  scripts.
- **Test before submitting.** These scripts perform administrative actions.
  Validate changes in a **non-production** environment first, and describe how you
  tested in the PR.
- **Style.** Follow the conventions of the file you are editing (naming,
  parameter blocks, comment density). Prefer clarity over cleverness.

## Reporting issues

- **Bugs / improvements:** open a GitHub Issue with steps to reproduce and the
  affected script path(s).
- **Security vulnerabilities:** do **not** open a public issue — follow
  [SECURITY.md](SECURITY.md) to report privately.

## License of contributions

By submitting a contribution, you agree that it will be licensed under the
repository's [MIT License](LICENSE).
