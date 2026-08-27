#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== RwEgressHome ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
MARKER="egress-$$-$(date +%s)"
out=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c "echo $MARKER > /home/sandbox-user/egress_test.txt && cat /home/sandbox-user/egress_test.txt" 2>&1)
fout=$(echo "$out" | grep -v '^\[SYS-LOG\]')
if echo "$fout" | grep -q "$MARKER"; then
  pass 'write inside sandbox persists in home (C1)'
else
  fail "egress failed: $fout"
fi
if [[ -f "$EPHEMERAL/home/sandbox-user/egress_test.txt" ]]; then
  pass 'file visible on host after sandbox exit (C2)'
else
  fail 'file not on host'
fi

results
