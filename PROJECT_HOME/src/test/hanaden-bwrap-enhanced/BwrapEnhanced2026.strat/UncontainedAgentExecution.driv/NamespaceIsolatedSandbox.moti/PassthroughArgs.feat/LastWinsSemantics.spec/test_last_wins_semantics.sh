#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== LastWinsSemantics ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
# C1: CLI --setenv last wins (repeated keys)
out=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" --setenv CONTEST first --setenv CONTEST middle --setenv CONTEST last -- /bin/bash -c 'echo $CONTEST' 2>&1)
fout=$(echo "$out" | grep -v '^\[SYS-LOG\]')
if echo "$fout" | grep -q 'last'; then
  pass 'last --setenv wins in bwrap (C1 -- bwrap processes flags L-to-R)'
else
  fail "last-wins failed: $fout"
fi
# C2: BWRAP_PASSTHROUGH_ARGS appended AFTER engine defaults (L488)
# So a --setenv via CLI to bwrap-enhanced.sh comes AFTER engine-set vars
out2=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" --setenv CONTEST passthrough_last -- /bin/bash -c 'echo $CONTEST' 2>&1)
fout2=$(echo "$out2" | grep -v '^\[SYS-LOG\]')
if echo "$fout2" | grep -q 'passthrough_last'; then
  pass 'CLI --setenv appended last wins over engine defaults (C2 -- code SST L488)'
else
  fail "CLI passthrough-last failed: $fout2"
fi

results
