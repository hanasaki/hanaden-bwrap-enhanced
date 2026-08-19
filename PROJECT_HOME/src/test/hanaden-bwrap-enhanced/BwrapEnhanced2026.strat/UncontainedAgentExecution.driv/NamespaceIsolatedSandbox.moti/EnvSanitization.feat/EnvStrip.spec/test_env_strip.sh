#!/bin/bash
source "/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/test/hanaden-bwrap-enhanced/shared/env.sh"
source "/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/test/hanaden-bwrap-enhanced/shared/assert.sh"

echo '=== EnvStrip ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
export LEAK_TEST_VAR=SHOULD_NOT_APPEAR
out=$("/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c 'env' 2>&1)
echo "$out" | grep -q 'LEAK_TEST_VAR' && fail 'host env leaked into sandbox (C1)' || pass 'host env vars stripped (--clear-env) (C1)'
# Known injected vars should be present
echo "$out" | grep -q 'HOME=' && pass 'HOME is set (C2)' || fail 'HOME missing'
echo "$out" | grep -q 'USER=' && pass 'USER is set (C3)' || fail 'USER missing'
echo "$out" | grep -q 'PATH=' && pass 'PATH is set (C4)' || fail 'PATH missing'

results
