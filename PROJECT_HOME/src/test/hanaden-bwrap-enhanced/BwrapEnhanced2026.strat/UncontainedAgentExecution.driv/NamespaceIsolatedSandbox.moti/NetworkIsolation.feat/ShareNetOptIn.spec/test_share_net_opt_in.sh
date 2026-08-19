#!/bin/bash
source "/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/test/hanaden-bwrap-enhanced/shared/env.sh"
source "/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/test/hanaden-bwrap-enhanced/shared/assert.sh"

echo '=== ShareNetOptIn ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
out=$("/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" --share-net -- /bin/bash -c 'cat /proc/net/dev' 2>&1)
fout=$(echo "$out" | grep -v '^\[SYS-LOG\]' | grep -v 'Inter' | grep -v '^ face' | grep ':')
ifaces=$(echo "$fout" | grep -c ':' || true)
if [[ $ifaces -gt 1 ]]; then
  pass "host network visible with --share-net ($ifaces interfaces) (C1)"
else
  fail "expected >1 interface with --share-net, got $ifaces"
fi

results
