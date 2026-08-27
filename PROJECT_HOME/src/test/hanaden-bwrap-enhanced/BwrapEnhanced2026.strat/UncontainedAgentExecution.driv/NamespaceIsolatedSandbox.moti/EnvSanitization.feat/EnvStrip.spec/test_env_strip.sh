#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== EnvStrip ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
export LEAK_TEST_VAR=SHOULD_NOT_APPEAR
out=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c 'env' 2>&1)
echo "$out" | grep -q 'LEAK_TEST_VAR' && fail 'host env leaked into sandbox (C1)' || pass 'host env vars stripped (--clear-env) (C1)'
# Known injected vars should be present
echo "$out" | grep -q 'HOME=' && pass 'HOME is set (C2)' || fail 'HOME missing'
echo "$out" | grep -q 'USER=' && pass 'USER is set (C3)' || fail 'USER missing'
echo "$out" | grep -q 'PATH=' && pass 'PATH is set (C4)' || fail 'PATH missing'

results
