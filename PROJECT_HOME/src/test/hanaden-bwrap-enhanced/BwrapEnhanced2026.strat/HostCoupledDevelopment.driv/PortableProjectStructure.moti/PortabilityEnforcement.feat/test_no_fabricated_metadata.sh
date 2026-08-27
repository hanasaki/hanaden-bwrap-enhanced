#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
# Spec: NoFabricatedMetadata / KI-004 Governance Audit Check
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== NoFabricatedMetadata ==='
SPEC_DIR="$WS/PROJECT_HOME/docs/architecture-design-features-specs/BwrapEnhanced2026.strat"

# NFM-001: Zero fabricated static timestamps (2026-08-18T16:08:59Z) in spec YAML frontmatters
fab_ts_count=$(grep -rn '2026-08-18T16:08:59Z' "$SPEC_DIR/" --include='*.md' | wc -l || true)
if [[ "$fab_ts_count" -eq 0 ]]; then
  pass "zero fabricated timestamps in specs (NFM-001)"
else
  fail "$fab_ts_count specs contain fabricated timestamp 2026-08-18T16:08:59Z (NFM-001)"
fi

# NFM-002: Zero fabricated runtime iteration counts in static specs
fab_iter_count=$(grep -rn 'iterations:[[:space:]]*[1-9]' "$SPEC_DIR/" --include='*.md' | wc -l || true)
if [[ "$fab_iter_count" -eq 0 ]]; then
  pass "zero fabricated iteration counts in specs (NFM-002)"
else
  fail "$fab_iter_count specs contain runtime iteration counts in frontmatter (NFM-002)"
fi

results
