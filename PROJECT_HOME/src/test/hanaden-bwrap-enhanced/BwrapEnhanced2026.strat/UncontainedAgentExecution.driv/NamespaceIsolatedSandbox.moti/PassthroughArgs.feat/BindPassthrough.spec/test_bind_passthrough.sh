#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== BindPassthrough ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
TMPF=$(mktemp)
echo 'bind_passthrough_content' > "$TMPF"
# Code SST: --ro-bind src dst parsed by CLI -> appended to bwrap_args
out=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" --ro-bind "$TMPF" /home/sandbox-user/bound_file -- /bin/bash -c 'cat /home/sandbox-user/bound_file' 2>&1)
fout=$(echo "$out" | grep -v '^\[SYS-LOG\]')
rm -f "$TMPF"
if echo "$fout" | grep -q 'bind_passthrough_content'; then
  pass '--ro-bind CLI arg passed through to bwrap (C1 -- code SST L757)'
else
  fail "bind passthrough failed: $fout"
fi

results
