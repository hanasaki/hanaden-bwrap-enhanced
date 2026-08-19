#!/bin/bash
source "/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/test/hanaden-bwrap-enhanced/shared/env.sh"
source "/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/test/hanaden-bwrap-enhanced/shared/assert.sh"

echo '=== X11Socket ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
if [[ -z "$DISPLAY" ]]; then
  skip 'SKIP: no X11 display on host'
  "/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/true 2>/dev/null; ec=$?
  if [[ $ec -eq 0 ]]; then pass 'sandbox exits 0 without X11 (MUST-NOT-FATAL) (C1)'
  else fail "sandbox FAILed: ec=$ec"; fi
else
  out=$("/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c 'ls /tmp/.X11-unix/ 2>&1' 2>&1)
  fout=$(echo "$out" | grep -v '^\[SYS-LOG\]')
  if echo "$fout" | grep -qE 'X[0-9]'; then
    pass 'X11 socket bound inside sandbox (C1)'
  else
    fail "X11 socket missing: $fout"
  fi
fi

results
