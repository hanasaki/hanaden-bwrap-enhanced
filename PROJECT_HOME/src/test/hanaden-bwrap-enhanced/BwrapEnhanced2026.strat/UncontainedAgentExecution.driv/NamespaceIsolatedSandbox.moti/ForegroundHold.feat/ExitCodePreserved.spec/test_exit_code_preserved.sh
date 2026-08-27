#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== ExitCodePreserved ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
ALL_PASS=true
for expected in 0 1 2 42 127; do
  "$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c "exit $expected" 2>/dev/null
  actual=$?
  if [[ $actual -eq $expected ]]; then
    pass "exit $expected propagated (C1)"
  else
    fail "expected $expected got $actual"
    ALL_PASS=false
  fi
done

results
