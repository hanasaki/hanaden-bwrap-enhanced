#!/usr/bin/env bash
# (c) 2026-* Frederick Bloom -- lib/fixture.bash -- Hanaden AI
# Shared BATS fixture helpers.  Source with: load '../lib/fixture'
# All helpers reference SCOPE-very-narrow.md §1, §2.
# ==============================================================================

# Path to the script under test (src/main — never boot/)
SCRIPT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../../main/hanaden-bwrap-enhanced" && pwd)/bwrap-enhanced.sh"

# SCOPE §2 default virtual user name
VIRTUAL_USER="sandbox_user"

# ---------------------------------------------------------------------------
# _mk_vroot — SCOPE §2 caller-setup: create minimal OS-skeleton vroot in tmpdir
# Returns path via stdout.
# ---------------------------------------------------------------------------
_mk_vroot() {
    local v
    v="$(mktemp -d)"
    mkdir -p "${v}"/{usr,etc,home,proc,dev,tmp,run,opt,var}
    ln -sfn usr/bin   "${v}/bin"
    ln -sfn usr/lib   "${v}/lib"
    ln -sfn usr/lib64 "${v}/lib64"
    mkdir -p "${v}/home/${VIRTUAL_USER}"
    echo "$v"
}

# ---------------------------------------------------------------------------
# _dry  — invoke script with --dry-run (resolves flags, no bwrap exec)
#         Usage: _dry [extra flags before --]
# ---------------------------------------------------------------------------
_dry() {
    run bash "$SCRIPT" --dry-run "$@" -- bash 2>&1
}

# ---------------------------------------------------------------------------
# _val  — invoke script with --validate against a real vroot
#         Usage: _val VROOT [extra flags]
# ---------------------------------------------------------------------------
_val() {
    local v="$1"; shift
    run bash "$SCRIPT" --validate \
        --virtual-user-name     "${VIRTUAL_USER}" \
        --host-real-root        "${v}" \
        --host-real-home-parent "${v}/home" \
        "$@" -- bash 2>&1
}
