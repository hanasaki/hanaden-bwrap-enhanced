#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== UsrMergeSymlinks ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
out=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c 'readlink /bin; readlink /lib 2>/dev/null; readlink /lib64 2>/dev/null' 2>&1)
fout=$(echo "$out" | grep -v '^\[SYS-LOG\]')
if echo "$fout" | grep -qE 'usr/bin|usr/lib'; then
  pass '/bin or /lib -> usr/* (C1)'
else
  fail "no usr-merge symlinks: $fout"
fi
out2=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c 'readlink -f /bin' 2>&1)
fout2=$(echo "$out2" | grep -v '^\[SYS-LOG\]')
if echo "$fout2" | grep -q '/usr/bin'; then
  pass '/bin -> /usr/bin confirmed (C2)'
else
  fail "readlink /bin: $fout2"
fi

results
