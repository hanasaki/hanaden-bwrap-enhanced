#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== ProfileDirSuppression ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
out=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c 'cat /etc/profile' 2>&1)
fout=$(echo "$out" | grep -v '^\[SYS-LOG\]')
if echo "$fout" | grep -qvE 'ORIG_PATH|conda|nvm|/home/hanasaki|source /etc/profile.d'; then
  pass 'host /etc/profile suppressed (C1)'
else
  fail "host profile leaked: $fout"
fi
if echo "$fout" | grep -q 'PATH'; then
  pass 'minimal profile has PATH set (C2)'
else
  fail 'minimal profile missing PATH'
fi

results
