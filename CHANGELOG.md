# Changelog

All notable changes to omarchy-dkms-audio-guard. Versions follow [Semantic Versioning](https://semver.org/).
Versions before the release of 2026-09-30 were assigned retroactively from the commit history.

## 1.0.1 – 2026-09-30

### Changed

- Author set to "Claude Code / Thomas Alt" (was "Omarchy"); display name "DKMS Audio Guard"; README: Changelog section; this CHANGELOG.

## 1.0.0 – 2026-09-30

### Added

- Initial release: checks every installed kernel for the snd_hda_macbookpro DKMS build and that the loaded module is that build; notifies once per boot; bundled fix runs `dkms install` for kernels missing it.
