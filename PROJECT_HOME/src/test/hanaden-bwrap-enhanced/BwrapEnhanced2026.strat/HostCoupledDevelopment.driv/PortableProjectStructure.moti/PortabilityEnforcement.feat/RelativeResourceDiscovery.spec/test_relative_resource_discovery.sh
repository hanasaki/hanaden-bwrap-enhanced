#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
# Spec: RelativeResourceDiscovery.spec -- language-agnostic principle check
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== RelativeResourceDiscovery ==='

# Self-exclusion: this test and siblings contain literal path strings in grep patterns
EXCL_DIR="HostCoupledDevelopment.driv"

# RRD-C1: No absolute source lines (source "/absolute/...")
fail_count=0
while IFS= read -r f; do
  # Skip enforcement tests (they contain the patterns as test data)
  [[ "$f" == *"$EXCL_DIR"* ]] && continue
  # Check for 'source "/...' at start of line (not in comments)
  matches=$(grep -cn '^source "/' "$f" || true)
  if [[ "$matches" -gt 0 ]]; then
    echo "  VIOLATION: $(basename "$f") has $matches absolute source line(s)"
    fail_count=$((fail_count + matches))
  fi
done < <(find "$WS/PROJECT_HOME/src" -name '*.sh' -type f)

if [[ "$fail_count" -eq 0 ]]; then
  pass "zero absolute source paths in .sh files (RRD-C1)"
else
  fail "$fail_count absolute source paths found (RRD-C1)"
fi

# RRD-C2: No hardcoded path variable assignments
assign_count=$(grep -rn '="/homes/' \
  "$WS/PROJECT_HOME/src/" \
  --include='*.sh' \
  | grep -v "$EXCL_DIR" \
  | grep -cv '#.*=' || true)
if [[ "$assign_count" -eq 0 ]]; then
  pass "zero hardcoded path assignments in .sh files (RRD-C2)"
else
  fail "$assign_count hardcoded path assignments found (RRD-C2)"
fi

results
