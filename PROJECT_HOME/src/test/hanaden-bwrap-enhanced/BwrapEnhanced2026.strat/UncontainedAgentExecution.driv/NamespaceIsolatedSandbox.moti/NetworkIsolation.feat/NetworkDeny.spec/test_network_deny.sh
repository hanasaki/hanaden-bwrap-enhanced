#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== NetworkDeny ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
out=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c 'cat /proc/net/dev' 2>&1)
fout=$(echo "$out" | grep -v '^\[SYS-LOG\]' | grep -v 'Inter' | grep -v '^ face' | grep ':')
ifaces=$(echo "$fout" | grep -v '^\s*lo:' | grep -c ':' || true)
if [[ $ifaces -eq 0 ]]; then
  pass 'only loopback interface inside sandbox (network isolated) (C1)'
else
  fail "unexpected non-lo interfaces ($ifaces): $fout"
fi

results
