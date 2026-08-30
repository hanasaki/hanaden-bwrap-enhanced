#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_bwrap_version_min.bats -- Hanaden AI
# SPEC: BwrapVersionMin.spec -- bwrap version >= 0.3.0
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

    SHADOW_DIR="$(mktemp -d)"
    local cmds=(bash printf id awk cat realpath mktemp head cut tr sed grep
                mkdir ln rm chmod date env command newuidmap newgidmap)
    for cmd in "${cmds[@]}"; do
        local src
        src="$(command -v "$cmd" 2>/dev/null || true)"
        [ -n "$src" ] && ln -sf "$src" "${SHADOW_DIR}/${cmd}" 2>/dev/null || true
    done

    # Stub newuidmap/newgidmap if not present
    for bin in newuidmap newgidmap; do
        if [ ! -x "${SHADOW_DIR}/${bin}" ]; then
            printf '#!/bin/sh\nexit 0\n' > "${SHADOW_DIR}/${bin}"
            chmod +x "${SHADOW_DIR}/${bin}"
        fi
    done

    # Create a mock /proc/sys for the user-ns check
    MOCK_PROC="$(mktemp -d)"
    mkdir -p "${MOCK_PROC}/kernel"
    echo "1" > "${MOCK_PROC}/kernel/unprivileged_userns_clone"
}

teardown() {
    [ -d "${SHADOW_DIR:-}" ] && rm -rf "$SHADOW_DIR"
    [ -d "${MOCK_PROC:-}" ] && rm -rf "$MOCK_PROC"
}

# Create a fake bwrap that reports a specific version
_make_bwrap_stub() {
    local version="$1"
    cat > "${SHADOW_DIR}/bwrap" <<EOFSTUB
#!/bin/sh
if [ "\$1" = "--version" ]; then
    echo "bubblewrap ${version}"
    exit 0
fi
# For all other invocations, succeed
exit 0
EOFSTUB
    chmod +x "${SHADOW_DIR}/bwrap"
}

_run_with_bwrap_version() {
    local version="$1"; shift
    _make_bwrap_stub "$version"
    PATH="${SHADOW_DIR}" BWRAP_PREFLIGHT_PROC_BASE="${MOCK_PROC}" \
        bash "$SCRIPT" "$@" 2>&1
}

# ---------------------------------------------------------------------------
@test "PF-VER-001: bwrap version 0.8.0 -- passes" {
    run _run_with_bwrap_version "0.8.0" --dry-run -- /bin/true
    [ "$status" -ne 2 ]
}

@test "PF-VER-002: bwrap version 0.2.1 -- FATAL exit 2" {
    run _run_with_bwrap_version "0.2.1" -- /bin/true
    [ "$status" -eq 2 ]
}

@test "PF-VER-003: bwrap version 0.2.1 -- stderr contains [FATAL]" {
    run _run_with_bwrap_version "0.2.1" -- /bin/true
    [[ "$output" == *"[FATAL]"* ]]
    [[ "$output" == *"0.3.0"* ]]
}
