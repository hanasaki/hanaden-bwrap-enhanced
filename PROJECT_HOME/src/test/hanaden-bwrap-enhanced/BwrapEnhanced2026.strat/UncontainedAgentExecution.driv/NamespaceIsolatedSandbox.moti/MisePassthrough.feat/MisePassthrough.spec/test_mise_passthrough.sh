#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== MisePassthrough ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
MISE_BIN=''
for p in "$HOME/.local/bin/mise" "$(which mise 2>/dev/null)"; do
  if [[ -x "$p" ]]; then MISE_BIN="$p"; break; fi
done
if [[ -z "$MISE_BIN" ]]; then
  fail 'FAIL: mise binary absent -- MisePassthrough requires mise on host (C1)'
else
  MISE_DIR=$(dirname "$MISE_BIN")
  out=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" --ro-bind "$MISE_BIN" "$MISE_BIN" --dir "$MISE_DIR" -- "$MISE_BIN" --version 2>&1)
  fout=$(echo "$out" | grep -v '^\[SYS-LOG\]')
  if echo "$fout" | grep -qiE 'mise [0-9]|[0-9]+\.[0-9]'; then
    pass "mise bound RO and runs: $(echo $fout | head -1) (C1)"
  else
    fail "mise did not run inside sandbox: $fout"
  fi
fi

results
