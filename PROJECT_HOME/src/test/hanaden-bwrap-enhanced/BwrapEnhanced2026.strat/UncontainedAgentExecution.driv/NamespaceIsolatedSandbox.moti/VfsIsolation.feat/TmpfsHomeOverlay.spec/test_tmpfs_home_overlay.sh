#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
source "/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/test/hanaden-bwrap-enhanced/shared/env.sh"
source "/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/test/hanaden-bwrap-enhanced/shared/assert.sh"

echo '=== TmpfsHomeOverlay ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
out=$("/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c 'ls /homes 2>&1' 2>&1)
fout=$(echo "$out" | grep -v '^\[SYS-LOG\]')
if echo "$fout" | grep -qvE 'hanasaki|Bloom|dev-projects|home-remote'; then
  pass '/homes is empty/hidden — PROJECT_HOME not visible (C1)'
else
  fail "/homes leaks host paths: $fout"
fi
out2=$("/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c 'ls -d /home/sandbox-user && echo DIR_EXISTS' 2>&1)
fout2=$(echo "$out2" | grep -v '^\[SYS-LOG\]')
if echo "$fout2" | grep -q 'DIR_EXISTS'; then
  pass '/home/sandbox-user exists inside sandbox (C2)'
else
  fail "sandbox-user home missing: $fout2"
fi

results
