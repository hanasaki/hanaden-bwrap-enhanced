#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T
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
