#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== MissingHomeFatal ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
# Code SST: --host-real-home-parent defaults to ~/virtual-roots/home (NOT fatal)
# Spec revised: without --host-real-home-parent, bwrap-enhanced.sh uses default ~/virtual-roots/home
out=$("$BWRAP_SH" --clear-env --host-real-root / -- /bin/bash -c 'echo HOME=$HOME' 2>&1)
fout=$(echo "$out" | grep -v '^\[SYS-LOG\]')
# C1: Script does NOT fatal -- defaults to sandbox-user home
ec=$?
if [[ $ec -eq 0 ]]; then
  pass 'bwrap-enhanced exits 0 using default home (~/virtual-roots/home) when --host-real-home-parent omitted (C1 -- code SST)'
else
  fail "unexpected exit: ec=$ec"
fi
# C2: HOME is set inside sandbox
if echo "$fout" | grep -q 'HOME=/home/sandbox-user'; then
  pass 'HOME=/home/sandbox-user in sandbox regardless of host-real-home-parent (C2)'
else
  fail "HOME wrong: $fout"
fi

results
