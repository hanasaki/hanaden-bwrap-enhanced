#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== TmpfsHomeOverlay ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
out=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c 'ls /homes 2>&1' 2>&1)
fout=$(echo "$out" | grep -v '^\[SYS-LOG\]')
if echo "$fout" | grep -qvE 'hanasaki|Bloom|dev-projects|home-remote'; then
  pass '/homes is empty/hidden -- PROJECT_HOME not visible (C1)'
else
  fail "/homes leaks host paths: $fout"
fi
out2=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c 'ls -d /home/sandbox-user && echo DIR_EXISTS' 2>&1)
fout2=$(echo "$out2" | grep -v '^\[SYS-LOG\]')
if echo "$fout2" | grep -q 'DIR_EXISTS'; then
  pass '/home/sandbox-user exists inside sandbox (C2)'
else
  fail "sandbox-user home missing: $fout2"
fi

results
