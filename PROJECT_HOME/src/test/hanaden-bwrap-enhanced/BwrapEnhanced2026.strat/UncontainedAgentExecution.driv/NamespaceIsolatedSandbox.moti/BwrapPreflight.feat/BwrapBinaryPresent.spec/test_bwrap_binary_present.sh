#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
source "/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/test/hanaden-bwrap-enhanced/shared/env.sh"
source "/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/test/hanaden-bwrap-enhanced/shared/assert.sh"
echo "=== BwrapBinaryPresent ==="

# C1: bwrap on PATH
if which bwrap &>/dev/null; then pass "bwrap found at: $(which bwrap)"; else fail "bwrap not on PATH"; fi
# C2: bwrap executable
if [[ -x "$(which bwrap 2>/dev/null)" ]]; then pass "bwrap is executable"; else fail "bwrap not executable"; fi
# C3: bwrap --version exits 0
if bwrap --version &>/dev/null; then pass "bwrap --version: $(bwrap --version 2>&1 | head -1)"; else fail "bwrap --version failed"; fi

results
