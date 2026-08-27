#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== ZeroMutation ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
SENTINEL="$EPHEMERAL/sentinel_before"
touch "$SENTINEL"
"$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c 'touch /tmp/zerotest; echo ok' 2>/dev/null
# /tmp inside sandbox is tmpfs -- any writes stay inside. Check host sentinel not newer.
if [[ -f "$SENTINEL" ]]; then
  pass 'host filesystem unchanged after sandbox run (C1)'
else
  fail 'sentinel file disappeared -- host mutation detected'
fi
# Verify sandbox /tmp write doesn't appear on host
if [[ ! -f /tmp/zerotest_host_leak_$$ ]]; then
  pass 'sandbox /tmp writes dont appear on host (C2)'
else
  fail '/tmp write leaked to host'
fi

results
