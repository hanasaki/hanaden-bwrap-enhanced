#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_bwrap_minimal_smoke.bats -- Hanaden AI
# SPEC: BwrapMinimalSmoke.spec -- minimal bwrap sandbox MUST launch
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

    for bin in newuidmap newgidmap; do
        if [ ! -x "${SHADOW_DIR}/${bin}" ]; then
            printf '#!/bin/sh\nexit 0\n' > "${SHADOW_DIR}/${bin}"
            chmod +x "${SHADOW_DIR}/${bin}"
        fi
    done

    MOCK_PROC="$(mktemp -d)"
    mkdir -p "${MOCK_PROC}/kernel"
    echo "1" > "${MOCK_PROC}/kernel/unprivileged_userns_clone"

    export SHADOW_DIR MOCK_PROC SCRIPT
}

teardown() {
    [ -d "${SHADOW_DIR:-}" ] && rm -rf "$SHADOW_DIR"
    [ -d "${MOCK_PROC:-}" ] && rm -rf "$MOCK_PROC"
}

_make_bwrap_stub() {
    local smoke_exit="$1"
    cat > "${SHADOW_DIR}/bwrap" <<EOFSTUB
#!/bin/sh
if [ "\$1" = "--version" ]; then
    echo "bubblewrap 0.8.0"
    exit 0
fi
exit ${smoke_exit}
EOFSTUB
    chmod +x "${SHADOW_DIR}/bwrap"
}

_run_smoke_pass() {
    _make_bwrap_stub 0
    PATH="${SHADOW_DIR}" BWRAP_PREFLIGHT_PROC_BASE="${MOCK_PROC}" \
        bash "$SCRIPT" "$@" 2>&1
}

_run_smoke_fail() {
    _make_bwrap_stub 1
    PATH="${SHADOW_DIR}" BWRAP_PREFLIGHT_PROC_BASE="${MOCK_PROC}" \
        bash "$SCRIPT" "$@" 2>&1
}

# ---------------------------------------------------------------------------
@test "PF-SMK-001: bwrap smoke passes -- preflight continues" {
    run _run_smoke_pass --dry-run -- /bin/true
    [ "$status" -ne 2 ]
}

@test "PF-SMK-002: bwrap smoke fails -- FATAL exit 2" {
    run _run_smoke_fail -- /bin/true
    [ "$status" -eq 2 ]
}

@test "PF-SMK-003: bwrap smoke fails -- stderr contains [FATAL]" {
    run _run_smoke_fail -- /bin/true
    [[ "$output" == *"[FATAL]"* ]]
}
