#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== MinimalProfile ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
out=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c 'cat /etc/profile' 2>&1)
fout=$(echo "$out" | grep -v '^\[SYS-LOG\]')
if echo "$fout" | grep -q 'PATH'; then
  pass '/etc/profile sets PATH (C1)'
else
  fail "no PATH in profile: $fout"
fi
if echo "$fout" | grep -qvE 'conda|nvm|rbenv|ORIG_PATH'; then
  pass 'no host profile.d sourced (C2)'
else
  fail 'host profile.d leaked into profile'
fi

results
