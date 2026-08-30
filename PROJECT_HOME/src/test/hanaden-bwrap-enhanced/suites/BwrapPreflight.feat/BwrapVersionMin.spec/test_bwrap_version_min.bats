#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_bwrap_version_min.bats -- Hanaden AI
# SPEC: BwrapVersionMin.spec -- bwrap version MUST be >= 0.3.0
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

@test "PF-VER-001: bwrap version >= 0.3.0" {
    local ver major minor
    ver="$(bwrap --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
    [ -n "$ver" ]
    major="${ver%%.*}"
    minor="${ver#*.}"; minor="${minor%%.*}"
    if [ "$major" -eq 0 ]; then
        [ "$minor" -ge 3 ]
    else
        [ "$major" -ge 1 ]
    fi
}

@test "PF-VER-002: script checks bwrap version in preflight" {
    run grep -q 'bwrap --version' "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "PF-VER-003: script rejects versions below minimum 0.3.0" {
    run grep -q 'below minimum' "$SCRIPT"
    [ "$status" -eq 0 ]
}
