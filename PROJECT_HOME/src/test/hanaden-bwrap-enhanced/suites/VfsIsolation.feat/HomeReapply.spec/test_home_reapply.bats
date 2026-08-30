#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_home_reapply.bats -- Hanaden AI
# SPEC: HomeReapply.spec -- home re-applied writable after root lock
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}

_dry() { bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1; }

@test "VFS-REAPPLY-001: home bind appears after --remount-ro" {
    run _dry
    # Find position of --remount-ro and the SECOND --bind HOME
    # Both must be present, and the second bind must follow remount-ro
    local remount_pos bind_pos
    remount_pos=$(echo "$output" | grep -n "\-\-remount-ro" | head -1 | cut -d: -f1)
    # Find the last --bind line containing /home/sandbox_user
    bind_pos=$(echo "$output" | grep -n "/home/sandbox_user" | tail -1 | cut -d: -f1)
    [ -n "$remount_pos" ]
    [ -n "$bind_pos" ]
    [ "$bind_pos" -gt "$remount_pos" ]
}
