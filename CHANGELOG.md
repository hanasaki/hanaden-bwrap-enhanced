<!-- (c) 2026-* Frederick Bloom -- CHANGELOG.md -- Hanaden AI -->

# Changelog

All notable changes to this project will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [v0.1.0] - 2026-08-18

### Added
- Full SDLC TDD spec hierarchy: 10 feature suites, 45 specs, 77 assertions
- Architecture tree: BwrapEnhanced2026.strat → UncontainedAgentExecution.driv → NamespaceIsolatedSandbox.moti
- SdlcTddRunReport template (convergence/drift engine)
- Enterprise doc templates: bug-report, incident-report
- GUI/toolchain passthrough flags: --enable-wayland, --enable-x11, --enable-audio, --enable-a11y, --enable-dbus, --enable-gnome, --enable-kde, --enable-chrome, --mise-enable
- Agent config files: AGENTS.md, GEMINI.md, CLAUDE.md with SCI enforcement

### Fixed
- **X11 Auth (XAUTHORITY):** --enable-x11 now RO-binds the XAUTHORITY file from host to /home/$USER/.Xauthority and remaps the env var. Previously only set the env var to the inaccessible host path, requiring insecure `xhost +` workaround.

## [initial-baseline] - 2026-07-29

### Added
- Initial bwrap-enhanced.sh sandbox wrapper
- Core VFS isolation, namespace isolation, identity injection
- PROJECT_HOME virtual filesystem structure
