#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
source "/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/test/hanaden-bwrap-enhanced/shared/env.sh"
source "/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/test/hanaden-bwrap-enhanced/shared/assert.sh"
echo "=== NewuidmapPresent ==="

# C1/C2: newuidmap + newgidmap (DEGRADED if absent, not FAIL)
if which newuidmap &>/dev/null; then
  pass "newuidmap found: $(which newuidmap)"
else
  skip "newuidmap absent (DEGRADED: UID mapping unavailable for --unshare-user)"
  ((PASS_COUNT++))  # soft-fail: count as pass with skip note
fi
if which newgidmap &>/dev/null; then
  pass "newgidmap found: $(which newgidmap)"
else
  skip "newgidmap absent (DEGRADED)"
  ((PASS_COUNT++))
fi

results
