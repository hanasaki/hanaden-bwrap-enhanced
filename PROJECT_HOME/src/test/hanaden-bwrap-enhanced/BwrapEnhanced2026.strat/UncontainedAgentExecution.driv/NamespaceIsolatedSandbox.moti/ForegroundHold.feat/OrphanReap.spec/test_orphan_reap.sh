#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== OrphanReap ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
T_START=$(date +%s%3N)
out=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c '(sleep 0.5) & wait $!; echo ORPHAN_REAPED' 2>&1)
T_END=$(date +%s%3N)
DUR=$((T_END - T_START))
fout=$(echo "$out" | grep -v '^\[SYS-LOG\]')
if echo "$fout" | grep -q 'ORPHAN_REAPED'; then
  pass 'orphan bg process reaped (C1)'
else
  fail "reap failed: $fout"
fi
if [[ $DUR -ge 400 ]]; then
  pass "sandbox waited for orphan (${DUR}ms >= 400ms) (C2)"
else
  fail "sandbox didn't wait: ${DUR}ms"
fi

results
