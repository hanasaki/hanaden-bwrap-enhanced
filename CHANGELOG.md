<!-- (c) 2026-* Frederick Bloom -- CHANGELOG.md -- Hanaden AI -->

# Changelog

All notable changes to this project will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [v0.4.1-beta] - 2026-09-09

### Changed
- AI-HITL collab docs renamed to NextStateEvolve naming convention:
  - Folder: CliRevision.ai-hitl.collab-0.0.2 -> NextStateEvolveTo041.ai-hitl.collab-0.0.2
  - Doc 1: CliRevision -> NextStateEvolveCli (Evolution Spec -- full SDLC hierarchy for CLI)
  - Doc 2: TestHarnessGapAnalysis -> NextStateEvolveBashTestHarnessGeneric (Analysis-Driven Plan)
  - Doc 3: NextStateEvolveExec (Execution Controller -- pending creation)
- Established 3-doc structure: evolution spec + analysis-driven plan + execution controller

## [v0.4.1] - 2026-09-03

### Added
- Release docs: `docs/releases/v[semver]-[origin|release].md` for all versions
- 176 BATS test suites across 43 feature suites
- Test harness runner with auto-discovery
- Library files: shell converters, Python report generators, JSON schemas
- 305 architecture/design/feature/spec documents
- 174 workstream kanban structure files
- 75 generic SDLC engine specifications

### Changed
- CLI subcommand dispatcher: provision, fsck, start (impl); stop, ls (stubs)
- All passthrough flags: --NOUN-passthrough convention
- mise.toml: project-scoped toolchain
- .gitignore: add **/target/ and /.worktrees/
- Frederick-Bloom-license.md: restructured, inline CLA
- CONTRIBUTING.md: CLA link -> Frederick-Bloom-license.md
- generic-sldc -> generic-sdlc (typo fix)
- Third-party legal refs -> third-party-ref-readonly/
- boot/bwrap-enhanced.sh remains at v0.2.1 (pinned)

### Fixed
- Removed LICENSE-COMMERCIAL.md badge (never existed)
- Fixed PROJECT_HOME/README.md: ../LICENSE -> ../LICENSE.md
- Removed broken CLA.md link
- Cleaned all non-ASCII from shell/bats files

### Removed
- 49 legacy .sh test files + 3 support files

## [v0.2.1] - 2026-08-25

### Changed
- **Legal Corpus Reorganization:** Added CLA reference collection, comparison matrix, and reorganized third-party open-source licenses.
- **Cruft Cleanup:** Removed 52 legacy/deprecated draft specs from `PROJECT_HOME/boot/specs/` and 8 obsolete bootstrap-0.0.3 execution run records.
- **Version Alignment:** Standardized project version baseline to `0.2.1` across all script headers and version files.

### Fixed
- **Documentation:** Corrected Mermaid syntax error in §3.1 Copyleft Strength Hierarchy.

## [v0.2.0] - 2026-08-21

### Added
- **Custom Dual-Licensing & Governance Framework:** AGPL-3.0-only reciprocal copyleft with Section 7 terms (Perpetual Attribution, Moral Rights Assertion, No AI/ML Training without authorization, Mandatory Contributor License Agreement).
- **Commercial Licensing Guide:** Multi-tier commercial licensing framework (`PROJECT_HOME/docs/legal/FrederickBloom/LICENSE-COMMERCIAL.md`).
- **Contributor License Agreement (CLA v1.0):** IP and patent assignment terms (`PROJECT_HOME/docs/legal/FrederickBloom/CLA.md`).
- **NOTICE & Third-Party Legal Artifacts:** Added `NOTICE` and official GNU `AGPL-3.0.txt`.
- **Enterprise VFS Architecture Topology:** Added Mermaid flowchart and MSC sequence diagrams in `README.md`.

### Changed
- **Unified Constitution:** Rewrote root `CONSTITUTION.md` codifying **The Immutable Principle** (*The jailer builds the jail; never trust a prisoner to build their own jail, or anyone else's jail*), Zero Side-Effects mandate, and explicit indemnification clause (§6).
- **DRY Refactoring:** Converted `PROJECT_HOME/CONSTITUTION.md` and `PROJECT_HOME/README.md` into lean pointer references.
- **Version Alignment:** Standardized project version baseline to `0.2.0` across all files.

## [v0.1.0] - 2026-08-18

### Added
- Full SDLC TDD spec hierarchy: 10 feature suites, 45 specs, 77 assertions
- Architecture tree: BwrapEnhanced2026.strat → UncontainedAgentExecution.driv → NamespaceIsolatedSandbox.moti
- SdlcTddRunReport template (convergence/drift engine)
- Enterprise doc templates: bug-report, incident-report
- GUI/toolchain passthrough flags (initial names): `--wayland-passthrough`, `--x11-passthrough`,
  `--audio-passthrough`, `--a11y-passthrough`, `--dbus-passthrough`, `--gnome-passthrough`,
  `--kde-passthrough`, `--mise-passthrough`
- Agent config files: AGENTS.md, GEMINI.md, CLAUDE.md with SCI enforcement

### Fixed
- **X11 Auth (XAUTHORITY):** `--x11-passthrough` now RO-binds the XAUTHORITY file from host to `/home/$USER/.Xauthority` and remaps the env var. Previously only set the env var to the inaccessible host path, requiring insecure `xhost +` workaround.

## [initial-baseline] - 2026-07-29

### Added
- Initial bwrap-enhanced.sh sandbox wrapper
- Core VFS isolation, namespace isolation, identity injection
- PROJECT_HOME virtual filesystem structure
