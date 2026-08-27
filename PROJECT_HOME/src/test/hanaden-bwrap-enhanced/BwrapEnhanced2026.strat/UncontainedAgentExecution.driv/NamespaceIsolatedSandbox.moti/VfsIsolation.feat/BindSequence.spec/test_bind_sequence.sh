#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== BindSequence ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
MARKER="seq-$$"
out=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c "echo $MARKER > /home/sandbox-user/seq_test.txt && echo OK" 2>&1)
fout=$(echo "$out" | grep -v '^\[SYS-LOG\]')
if echo "$fout" | grep -q OK; then
  pass 'home RW after --remount-ro (step 12 re-bind) (C1)'
else
  fail "post-remount write failed: $fout"
fi
out2=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c 'touch /usr/probe 2>&1; echo exitcode:$?' 2>&1)
fout2=$(echo "$out2" | grep -v '^\[SYS-LOG\]')
if echo "$fout2" | grep -qE 'exitcode:1|Read-only|EROFS|Permission'; then
  pass '/usr is read-only (step 2) (C2)'
else
  fail "usr may be writable: $fout2"
fi

results
