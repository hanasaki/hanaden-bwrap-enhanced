#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== PureBuiltinLoop ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
T_START=$(date +%s%3N)
"$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/true 2>/dev/null
T_END=$(date +%s%3N)
DUR=$((T_END - T_START))
if [[ $DUR -lt 5000 ]]; then
  pass "poll loop completes in <5s (pure builtins): ${DUR}ms (C1)"
else
  fail "poll loop too slow: ${DUR}ms"
fi
out=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c 'sleep 0.1 & wait; echo REAPED' 2>&1)
if echo "$out" | grep -q REAPED; then
  pass 'orphan children reaped before exit (C2)'
else
  fail "reap failed: $out"
fi

results
