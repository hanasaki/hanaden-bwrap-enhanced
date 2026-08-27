#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== EmptyCommandFatal ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
out=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" 2>&1)
ec=$?
if [[ $ec -ne 0 ]]; then
  pass "exits nonzero (ec=$ec) when CMD empty (C1)"
else
  fail 'should exit nonzero when CMD empty'
fi
if echo "$out" | grep -qi 'usage\|error\|fatal\|required\|command\|must'; then
  pass 'diagnostic message emitted (C2)'
else
  fail "no diagnostic: $(echo $out | grep -v SYS-LOG | head -3)"
fi

results
