#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
source "/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/test/hanaden-bwrap-enhanced/shared/env.sh"
source "/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/test/hanaden-bwrap-enhanced/shared/assert.sh"

echo '=== UnsetenvDirTmpfsPassthrough ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
# C1: --unsetenv via CLI (code SST L769)
out=$("/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" --setenv UNSET_ME will_be_removed --unsetenv UNSET_ME -- /bin/bash -c 'echo UNSET_ME=${UNSET_ME:-UNSET}' 2>&1)
fout=$(echo "$out" | grep -v '^\[SYS-LOG\]')
if echo "$fout" | grep -q 'UNSET_ME=UNSET'; then
  pass '--unsetenv CLI flag removes env var (C1 -- code SST L769)'
else
  fail "unsetenv failed: $fout"
fi
# C2: --dir via CLI creates directory inside sandbox (code SST L770)
out2=$("/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" --dir /tmp/newdir_cli_test -- /bin/bash -c 'ls -d /tmp/newdir_cli_test && echo DIREXISTS' 2>&1)
fout2=$(echo "$out2" | grep -v '^\[SYS-LOG\]')
if echo "$fout2" | grep -q 'DIREXISTS'; then
  pass '--dir CLI flag creates directory inside sandbox (C2 -- code SST L770)'
else
  fail "--dir failed: $fout2"
fi

results
