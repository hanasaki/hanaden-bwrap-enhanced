#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_bwrap_minimal_smoke.bats -- Hanaden AI
# SPEC: BwrapMinimalSmoke.spec -- minimal bwrap sandbox can be created
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

@test "PF-SMK-001: bwrap minimal sandbox smoke test passes" {
    run bwrap --ro-bind / / --unshare-user --die-with-parent /bin/true
    [ "$status" -eq 0 ]
}

@test "PF-SMK-002: script smoke test uses --ro-bind and --unshare-user" {
    run grep -q 'ro-bind / / --unshare-user' "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "PF-SMK-003: script has FATAL path for smoke failure" {
    run grep -q 'Minimal bwrap sandbox smoke test failed' "$SCRIPT"
    [ "$status" -eq 0 ]
}
