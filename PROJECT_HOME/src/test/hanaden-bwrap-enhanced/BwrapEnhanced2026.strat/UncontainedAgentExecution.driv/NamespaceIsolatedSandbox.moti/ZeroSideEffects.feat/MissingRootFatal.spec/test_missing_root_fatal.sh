#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
source "/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/test/hanaden-bwrap-enhanced/shared/env.sh"
source "/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/test/hanaden-bwrap-enhanced/shared/assert.sh"

echo '=== MissingRootFatal ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
# Code SST: --host-real-root defaults to ~/virtual-roots (NOT fatal)
out=$("/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh" --clear-env --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c 'echo OK' 2>&1)
fout=$(echo "$out" | grep -v '^\[SYS-LOG\]')
ec=$?
if [[ $ec -eq 0 ]]; then
  pass 'bwrap-enhanced exits 0 using default root (~/virtual-roots) when --host-real-root omitted (C1 -- code SST)'
else
  fail "unexpected exit: ec=$ec"
fi
if echo "$fout" | grep -q OK; then
  pass 'CMD runs inside sandbox even with default root (C2)'
else
  fail "CMD failed: $fout"
fi

results
