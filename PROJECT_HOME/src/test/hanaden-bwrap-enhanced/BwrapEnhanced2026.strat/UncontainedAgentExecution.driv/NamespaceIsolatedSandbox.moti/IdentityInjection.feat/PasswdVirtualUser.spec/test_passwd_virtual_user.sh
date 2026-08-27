#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== PasswdVirtualUser ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
out=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c 'cat /etc/passwd' 2>&1)
fout=$(echo "$out" | grep -v '^\[SYS-LOG\]')
if echo "$fout" | grep -q 'sandbox-user'; then
  pass 'sandbox-user entry in /etc/passwd (C1)'
else
  fail "sandbox-user missing: $(echo $fout | head -3)"
fi
if echo "$fout" | grep -q '/home/sandbox-user'; then
  pass 'home dir is /home/sandbox-user (C2)'
else
  fail "wrong home: $fout"
fi
out2=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /usr/bin/id -un 2>&1)
fout2=$(echo "$out2" | grep -v '^\[SYS-LOG\]')
if echo "$fout2" | grep -q 'sandbox-user'; then
  pass 'running as sandbox-user (C3)'
else
  fail "wrong user: $fout2"
fi

results
