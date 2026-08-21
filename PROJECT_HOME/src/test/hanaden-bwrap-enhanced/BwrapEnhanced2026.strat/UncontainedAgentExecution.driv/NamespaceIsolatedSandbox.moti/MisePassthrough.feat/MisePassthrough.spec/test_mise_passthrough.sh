#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
source "/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/test/hanaden-bwrap-enhanced/shared/env.sh"
source "/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/test/hanaden-bwrap-enhanced/shared/assert.sh"

echo '=== MisePassthrough ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
MISE_BIN=''
for p in "$HOME/.local/bin/mise" '/homes/home-local/hanasaki/.local/bin/mise' "$(which mise 2>/dev/null)"; do
  if [[ -x "$p" ]]; then MISE_BIN="$p"; break; fi
done
if [[ -z "$MISE_BIN" ]]; then
  fail 'FAIL: mise binary absent -- MisePassthrough requires mise on host (C1)'
else
  MISE_DIR=$(dirname "$MISE_BIN")
  out=$("/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" --ro-bind "$MISE_BIN" "$MISE_BIN" --dir "$MISE_DIR" -- "$MISE_BIN" --version 2>&1)
  fout=$(echo "$out" | grep -v '^\[SYS-LOG\]')
  if echo "$fout" | grep -qiE 'mise [0-9]|[0-9]+\.[0-9]'; then
    pass "mise bound RO and runs: $(echo $fout | head -1) (C1)"
  else
    fail "mise did not run inside sandbox: $fout"
  fi
fi

results
