#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
# Shared test assertion library for hanaden-bwrap-enhanced
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

pass() { echo "  PASS: $*"; ((PASS_COUNT++)); }
fail() { echo "  FAIL: $*"; ((FAIL_COUNT++)); }
skip() { echo "  SKIP: $*"; ((SKIP_COUNT++)); }

results() {
    echo "=== RESULTS: $PASS_COUNT passed, $FAIL_COUNT failed"
    [[ $FAIL_COUNT -eq 0 ]] && exit 0 || exit 1
}

# Strip SYS-LOG lines from bwrap output before assertion
strip_syslogs() { grep -v '^\[SYS-LOG\]' <<< "$1" || true; }

# Run bwrap sandbox, strip SYS-LOG from output
bwrap_out() {
    local out
    out=$("$@" 2>&1)
    strip_syslogs "$out"
}
