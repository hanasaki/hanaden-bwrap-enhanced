#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== SetenvPassthrough ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
# Code SST: --setenv parsed by bwrap-enhanced.sh CLI -> BWRAP_PASSTHROUGH_ARGS
out=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" --setenv PASSTHROUGH_VAR passthrough_value -- /bin/bash -c 'echo $PASSTHROUGH_VAR' 2>&1)
fout=$(echo "$out" | grep -v '^\[SYS-LOG\]')
if echo "$fout" | grep -q 'passthrough_value'; then
  pass '--setenv CLI arg passed through to bwrap (C1 -- code SST L762+)'
else
  fail "setenv passthrough failed: $fout"
fi

results
