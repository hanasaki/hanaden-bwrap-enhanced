#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== ShareNetOptIn ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
out=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" --share-net -- /bin/bash -c 'cat /proc/net/dev' 2>&1)
fout=$(echo "$out" | grep -v '^\[SYS-LOG\]' | grep -v 'Inter' | grep -v '^ face' | grep ':')
ifaces=$(echo "$fout" | grep -c ':' || true)
if [[ $ifaces -gt 1 ]]; then
  pass "host network visible with --share-net ($ifaces interfaces) (C1)"
else
  fail "expected >1 interface with --share-net, got $ifaces"
fi

results
