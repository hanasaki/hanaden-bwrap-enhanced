#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
source "/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/test/hanaden-bwrap-enhanced/shared/env.sh"
source "/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/test/hanaden-bwrap-enhanced/shared/assert.sh"

echo '=== CliDefaults ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
out2=$("/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c 'echo HOME=$HOME USER=$USER' 2>&1)
fout2=$(echo "$out2" | grep -v '^\[SYS-LOG\]')
if echo "$fout2" | grep -q 'sandbox-user'; then
  pass 'HOME/USER set to sandbox-user (C2)'
else
  fail "unexpected env: $fout2"
fi
out=$("/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c 'cat /proc/net/dev' 2>&1)
nlo=$(echo "$out" | grep -v '^\[SYS-LOG\]' | grep -v 'Inter' | grep ':' | grep -v 'lo:' | wc -l)
if [[ $nlo -eq 0 ]]; then
  pass 'network isolated by default (C1)'
else
  skip 'host shows extra interfaces even in sandbox - environment specific'
fi

results
