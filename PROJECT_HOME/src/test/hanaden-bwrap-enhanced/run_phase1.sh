#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARED="$SCRIPT_DIR/shared"
LOG="/tmp/bwrap-tdd-progress.log"

source "$SHARED/env.sh"
source "$SHARED/assert.sh"

BWRAP_SH="$WS/PROJECT_HOME/boot/bwrap-enhanced.sh"
FEAT_BASE="$SCRIPT_DIR/BwrapEnhanced2026.strat/UncontainedAgentExecution.driv/NamespaceIsolatedSandbox.moti"
EPHEM_BASE="/tmp/bwrap-tdd-351079"

TOTAL_PASS=0; TOTAL_FAIL=0; TOTAL_SKIP=0
PHASE_RESULTS=()

run_spec_test() {
  local spec_name="$1"
  local test_script="$2"
  echo ""
  echo "==[P1: $spec_name]=="
  local out
  out=$(bash "$test_script" 2>&1)
  local ec=$?
  echo "$out"
  local p=$(echo "$out" | grep -c 'PASS:' || true)
  local f=$(echo "$out" | grep -c 'FAIL:' || true)
  local s=$(echo "$out" | grep -c 'SKIP:' || true)
  TOTAL_PASS=$((TOTAL_PASS+p))
  TOTAL_FAIL=$((TOTAL_FAIL+f))
  TOTAL_SKIP=$((TOTAL_SKIP+s))
  if [[ $f -gt 0 || $ec -ne 0 ]]; then
    PHASE_RESULTS+=("FAIL:$spec_name")
    echo "SPEC_RESULT spec=$spec_name pass=$p fail=$f skip=$s ec=$ec" >> "$LOG"
  else
    PHASE_RESULTS+=("PASS:$spec_name")
    echo "SPEC_RESULT spec=$spec_name pass=$p fail=$f skip=$s ec=$ec" >> "$LOG"
  fi
}

echo "=== PHASE 1 START: $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" | tee -a "$LOG"
T1_START=$(date +%s%3N)

