#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== SandboxEntrypoint ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
out=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c 'echo ENTRYPOINT_OK' 2>&1)
fout=$(echo "$out" | grep -v '^\[SYS-LOG\]')
if echo "$fout" | grep -q 'ENTRYPOINT_OK'; then
  pass 'CMD executed inside sandbox (C1)'
else
  fail "CMD not executed: $fout"
fi
out2=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /usr/bin/id 2>&1)
fout2=$(echo "$out2" | grep -v '^\[SYS-LOG\]')
if echo "$fout2" | grep -q 'sandbox-user'; then
  pass 'runs as sandbox-user (C2)'
else
  fail "not sandbox-user: $fout2"
fi

results
