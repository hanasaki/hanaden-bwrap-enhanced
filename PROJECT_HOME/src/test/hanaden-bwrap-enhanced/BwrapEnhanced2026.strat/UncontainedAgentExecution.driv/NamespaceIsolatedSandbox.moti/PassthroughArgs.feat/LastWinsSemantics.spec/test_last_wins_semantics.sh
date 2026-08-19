#!/bin/bash
source "/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/test/hanaden-bwrap-enhanced/shared/env.sh"
source "/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/test/hanaden-bwrap-enhanced/shared/assert.sh"

echo '=== LastWinsSemantics ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
# C1: CLI --setenv last wins (repeated keys)
out=$("/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" --setenv CONTEST first --setenv CONTEST middle --setenv CONTEST last -- /bin/bash -c 'echo $CONTEST' 2>&1)
fout=$(echo "$out" | grep -v '^\[SYS-LOG\]')
if echo "$fout" | grep -q 'last'; then
  pass 'last --setenv wins in bwrap (C1 — bwrap processes flags L-to-R)'
else
  fail "last-wins failed: $fout"
fi
# C2: BWRAP_PASSTHROUGH_ARGS appended AFTER engine defaults (L488)
# So a --setenv via CLI to bwrap-enhanced.sh comes AFTER engine-set vars
out2=$("/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" --setenv CONTEST passthrough_last -- /bin/bash -c 'echo $CONTEST' 2>&1)
fout2=$(echo "$out2" | grep -v '^\[SYS-LOG\]')
if echo "$fout2" | grep -q 'passthrough_last'; then
  pass 'CLI --setenv appended last wins over engine defaults (C2 — code SST L488)'
else
  fail "CLI passthrough-last failed: $fout2"
fi

results
