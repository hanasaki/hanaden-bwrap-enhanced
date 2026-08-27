#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T
echo "=== UserNamespaceEnabled ==="

# C1: /proc/sys/kernel/unprivileged_userns_clone
if [[ -f /proc/sys/kernel/unprivileged_userns_clone ]]; then
  val=$(cat /proc/sys/kernel/unprivileged_userns_clone)
  if [[ "$val" == "1" ]]; then
    pass "unprivileged_userns_clone=1"
  else
    fail "unprivileged_userns_clone=$val (must be 1)"
  fi
else
  # Not present = allowed by default on this kernel
  pass "unprivileged_userns_clone: not controlled (allowed by default)"
fi
# C2: unshare -U actually works
if unshare -U /bin/true 2>/dev/null; then
  pass "unshare -U /bin/true exits 0"
else
  fail "unshare -U /bin/true failed (user namespaces not available)"
fi

results
