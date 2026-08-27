#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== SyncExecution ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
T_START=$(date +%s%3N)
"$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c 'sleep 0.3' 2>/dev/null
T_END=$(date +%s%3N)
DUR=$((T_END - T_START))
if [[ $DUR -ge 200 ]]; then
  pass "bwrap-enhanced.sh waited for CMD (sleep 0.3, actual ${DUR}ms) (C1)"
else
  fail "returned too fast: ${DUR}ms"
fi

results
