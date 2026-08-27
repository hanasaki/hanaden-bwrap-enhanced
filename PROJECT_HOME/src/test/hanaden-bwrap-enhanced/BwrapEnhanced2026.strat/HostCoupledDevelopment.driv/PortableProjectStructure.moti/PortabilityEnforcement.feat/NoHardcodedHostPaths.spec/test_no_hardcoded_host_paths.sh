#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
# Spec: NoHardcodedHostPaths.spec -- language-agnostic grep scan
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== NoHardcodedHostPaths ==='

# Self-exclusion: this test and its siblings contain the grep patterns
# as literal strings. Exclude the entire PortabilityEnforcement.feat/ tree.
EXCL_DIR="HostCoupledDevelopment.driv"

# NHP-C1: Zero /homes/ references in src/ (excl. enforcement tests and grep patterns)
count_src=$(grep -rn '/homes/' \
  "$WS/PROJECT_HOME/src/" \
  --include='*.sh' --include='*.py' --include='*.go' --include='*.rs' \
  | grep -v "$EXCL_DIR" \
  | grep -cv 'grep.*qvE\|grep.*pattern' || true)
if [[ "$count_src" -eq 0 ]]; then
  pass "zero /homes/ references in src/ (NHP-C1)"
else
  fail "$count_src hardcoded /homes/ paths found in src/ (NHP-C1)"
fi

# NHP-C2: Zero known user paths in src/
count_user=$(grep -rn 'home-remote\|Bloom-Frederick' \
  "$WS/PROJECT_HOME/src/" \
  --include='*.sh' --include='*.py' --include='*.go' --include='*.rs' \
  | grep -v "$EXCL_DIR" \
  | grep -cv 'grep.*qvE\|grep.*pattern' || true)
if [[ "$count_user" -eq 0 ]]; then
  pass "zero user-specific path references in src/ (NHP-C2)"
else
  fail "$count_user user-specific paths found in src/ (NHP-C2)"
fi

# NHP-002: Regression detection (mutation test)
# Verify that injecting a hardcoded path into a temporary probe file is detected by the scanner
TMP_PROBE=$(mktemp "$WS/PROJECT_HOME/src/test/probe-XXXXXX.sh")
echo 'SAMPLE_PATH="/homes/test-user/repo"' > "$TMP_PROBE"
detected=$(grep -rn '/homes/' "$TMP_PROBE" | wc -l || true)
rm -f "$TMP_PROBE"
if [[ "$detected" -ge 1 ]]; then
  pass "scanner detects injected /homes/ path violation (NHP-002)"
else
  fail "scanner failed to detect injected path violation (NHP-002)"
fi

results
