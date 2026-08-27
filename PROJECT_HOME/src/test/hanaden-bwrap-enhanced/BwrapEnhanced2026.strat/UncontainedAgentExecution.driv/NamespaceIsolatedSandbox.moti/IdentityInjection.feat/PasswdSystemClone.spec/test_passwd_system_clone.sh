#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== PasswdSystemClone ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
out=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c 'cat /etc/passwd' 2>&1)
fout=$(echo "$out" | grep -v '^\[SYS-LOG\]')
if echo "$fout" | grep -q '^root:'; then
  pass 'root entry in /etc/passwd (C1)'
else
  fail "root missing: $(echo $fout | head -3)"
fi
if echo "$fout" | grep -qE '^(nobody|daemon|bin):'; then
  pass 'system users cloned from host (C2)'
else
  skip 'no nobody/daemon (system-specific -- OK)'
fi

results
