#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
# Spec: NoHostTopologyInSpecs.spec -- language-agnostic spec purity check
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== NoHostTopologyInSpecs ==='

SPEC_DIR="$WS/PROJECT_HOME/docs/architecture-design-features-specs"

# NHT-C1: Zero autofs references in spec docs (excl. exceptions)
autofs_count=$(grep -rni 'autofs' \
  "$SPEC_DIR/" \
  --include='*.md' \
  | grep -cv 'secbul\|HostCoupledDevelopment\|\.analys\|brainstorm' || true)
if [[ "$autofs_count" -eq 0 ]]; then
  pass "zero autofs references in spec docs (NHT-C1)"
else
  fail "$autofs_count autofs references found in spec docs (NHT-C1)"
fi

# NHT-C2: Zero NFS references in spec docs (excl. exceptions)
nfs_count=$(grep -rniE '\bnfs\b' \
  "$SPEC_DIR/" \
  --include='*.md' \
  | grep -cv 'secbul\|HostCoupledDevelopment\|\.analys\|brainstorm' || true)
if [[ "$nfs_count" -eq 0 ]]; then
  pass "zero NFS references in spec docs (NHT-C2)"
else
  fail "$nfs_count NFS references found in spec docs (NHT-C2)"
fi

results
