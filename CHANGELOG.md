<!-- (c) 2026-* Frederick Bloom -- CHANGELOG.md -- Hanaden AI -->

# Changelog

All notable changes to this project will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [v0.2.2] - 2026-08-25

### Security
- **D-Bus Decoupling (`--enable-gnome`, `--enable-kde`):** `--enable-gnome` and `--enable-kde` no longer implicitly set `ENABLE_DBUS=true`. The D-Bus session bus (`/run/user/UID/bus`) is now **strictly absent** inside the sandbox unless `--enable-dbus` is explicitly passed. This closes a prior escape vector where GNOME/KDE desktop integration silently exposed host portals (file pickers, secret keyrings, systemd --user execution) without the caller's awareness.
- **`--enable-dbus` Help Text — Critical Warning:** Upgraded from a single-sentence warning to a detailed threat model listing all three escape vectors unlocked: (1) host filesystem browsing via portal file pickers, (2) host secret keyring access via `org.freedesktop.secrets`, (3) unconfined host command execution via `systemd --user`.

### Changed
- **Security Tier Table Rewrite:** Tiers reordered and relabelled to reflect the corrected isolation model:
  - Tier 1 `(media)`: `--enable-wayland --enable-audio` — zero host FS escape
  - Tier 2 `(accessible)`: + `--enable-a11y` — zero host FS escape
  - Tier 3 `(desktop)`: + `--enable-gnome` / `--enable-kde` — native themes/fonts; zero host FS escape
  - Tier 4 `(portal)`: + `--enable-dbus` — **PUNCHES A SECURITY HOLE**
- **Spec Docs Updated:** `GnomePassthrough.spec` and `KdePassthrough.spec` revised to reflect decoupled D-Bus behaviour; GN-005/KDE-005 test cases flipped from "bus socket present" → "bus absent (ISOLATED)"; Mermaid behavioral flow diagrams updated to remove the `ENABLE_DBUS=true (implied)` node.
- **Version Bump:** `0.2.1` → `0.2.2`.

### Fixed
- **Test Path Portability:** `test_gnome_passthrough.sh` and `test_kde_passthrough.sh` replaced hardcoded absolute NFS paths with portable `SCRIPT_DIR` / `PROJECT_DIR` traversal (`cd` up until `PROJECT_HOME/` is found). Tests now run correctly from any checkout location.

### Tests
- **GN-005 / KDE-005 — D-Bus Decoupling Assertion (new):** Both passthrough test scripts now include a second test that invokes the sandbox with only `--enable-gnome` / `--enable-kde` and asserts that `/run/user/$(id -u)/bus` is **absent** inside the sandbox, providing runtime proof of the decoupling guarantee.

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
- GUI/toolchain passthrough flags: --enable-wayland, --enable-x11, --enable-audio, --enable-a11y, --enable-dbus, --enable-gnome, --enable-kde, --enable-chrome, --mise-enable
- Agent config files: AGENTS.md, GEMINI.md, CLAUDE.md with SCI enforcement

### Fixed
- **X11 Auth (XAUTHORITY):** --enable-x11 now RO-binds the XAUTHORITY file from host to /home/$USER/.Xauthority and remaps the env var. Previously only set the env var to the inaccessible host path, requiring insecure `xhost +` workaround.

## [initial-baseline] - 2026-07-29

### Added
- Initial bwrap-enhanced.sh sandbox wrapper
- Core VFS isolation, namespace isolation, identity injection
- PROJECT_HOME virtual filesystem structure
