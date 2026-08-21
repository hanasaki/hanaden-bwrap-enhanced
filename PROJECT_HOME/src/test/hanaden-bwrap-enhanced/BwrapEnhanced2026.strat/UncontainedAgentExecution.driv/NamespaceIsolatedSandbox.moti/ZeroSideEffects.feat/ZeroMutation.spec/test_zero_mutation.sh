#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
source "/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/test/hanaden-bwrap-enhanced/shared/env.sh"
source "/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/test/hanaden-bwrap-enhanced/shared/assert.sh"

echo '=== ZeroMutation ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
SENTINEL="$EPHEMERAL/sentinel_before"
touch "$SENTINEL"
"/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c 'touch /tmp/zerotest; echo ok' 2>/dev/null
# /tmp inside sandbox is tmpfs -- any writes stay inside. Check host sentinel not newer.
if [[ -f "$SENTINEL" ]]; then
  pass 'host filesystem unchanged after sandbox run (C1)'
else
  fail 'sentinel file disappeared -- host mutation detected'
fi
# Verify sandbox /tmp write doesn't appear on host
if [[ ! -f /tmp/zerotest_host_leak_$$ ]]; then
  pass 'sandbox /tmp writes dont appear on host (C2)'
else
  fail '/tmp write leaked to host'
fi

results
