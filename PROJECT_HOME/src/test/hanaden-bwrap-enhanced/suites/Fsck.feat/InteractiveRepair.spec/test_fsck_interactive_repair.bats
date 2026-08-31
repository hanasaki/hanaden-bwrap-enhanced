#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_fsck_interactive_repair.bats -- Hanaden AI
# SPEC: Fsck.feat/InteractiveRepair -- -r flag: interactive repair prompts and responses
# REF:  SCOPE-very-narrow.md ### fsck -r
#
# -r (interactive repair): for each repairable error, fsck prints a [PROMPT] to
# stderr and reads a y/N answer from ${BWRAP_FSCK_TTY:-/dev/tty}.
# If the user types "y" or "Y", the error is repaired (exit bit 2);
# if they type anything else or EOF, the error is left unrepaired (exit bit 1).
#
# Testing strategy: set BWRAP_FSCK_TTY to a file containing pre-written answers
# (one per line). This makes -r fully scriptable without a real terminal.
#
# All post-repair assertions are raw filesystem primitives.
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    WORK="$(mktemp -d)"
    ROOT="${WORK}/vroot"
    ANSWERS="${WORK}/answers.txt"
    # provision the root for each test
    bash "$SCRIPT" provision \
        --host-real-root    "$ROOT" \
        --virtual-user-name sandbox_user
}
teardown() { rm -rf "$WORK"; }

# Write answers file and run fsck -r with BWRAP_FSCK_TTY pointing at it.
# cmd_fsck opens BWRAP_FSCK_TTY as fd 9 ONCE in the parent process before any
# subshells run. All read <&9 calls inherit this single open fd, so the file
# offset advances sequentially -- one answer consumed per read call.
# A plain regular file is sufficient; no FIFO needed.
#
# Usage: run_ir "line1\nline2\n..." [extra fsck args...]
run_ir() {
    local answers="$1"; shift
    printf '%b\n' "$answers" > "$ANSWERS"
    BWRAP_FSCK_TTY="$ANSWERS" run bash "$SCRIPT" fsck -r \
        --host-real-root    "$ROOT" \
        --virtual-user-name sandbox_user \
        "$@" 2>&1
}

# ---------------------------------------------------------------------------
# -r basics: mutex with -a, flag accepted, clean root
# ---------------------------------------------------------------------------

@test "FSCK-IR-001: -r is accepted (not unknown option)" {
    rm -rf "${ROOT}/usr"
    run_ir "n" --log-level FATAL
    [[ "$output" != *"unknown option"* ]]
}

@test "FSCK-IR-002: -a and -r together exit 1 (mutually exclusive)" {
    run bash "$SCRIPT" fsck -a -r --host-real-root "$ROOT"
    [ "$status" -eq 1 ]
    [[ "$output" == *"mutually exclusive"* ]]
}

@test "FSCK-IR-003: -r and -a together exit 1 (both orders)" {
    run bash "$SCRIPT" fsck -r -a --host-real-root "$ROOT"
    [ "$status" -eq 1 ]
    [[ "$output" == *"mutually exclusive"* ]]
}

@test "FSCK-IR-004: -r on clean root exits 0 (no prompts needed)" {
    printf '' > "$ANSWERS"  # no answers needed
    BWRAP_FSCK_TTY="$ANSWERS" run bash "$SCRIPT" fsck -r \
        --host-real-root    "$ROOT" \
        --virtual-user-name sandbox_user 2>&1
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# -r: answer "y" -> repair performed, raw verify
# ---------------------------------------------------------------------------

@test "FSCK-IR-005: -r 'y' repairs missing usr dir (raw)" {
    rm -rf "${ROOT}/usr"
    # usr is the first dir checked; needs one "y"
    run_ir "y"
    [ -d "${ROOT}/usr" ]
}

@test "FSCK-IR-006: -r 'y' on missing dir sets bit 2 in exit code" {
    rm -rf "${ROOT}/usr"
    run_ir "y"
    (( status & 2 ))
}

@test "FSCK-IR-007: -r 'Y' (uppercase) also repairs (raw)" {
    rm -rf "${ROOT}/usr"
    run_ir "Y"
    [ -d "${ROOT}/usr" ]
}

@test "FSCK-IR-008: -r 'y' repairs missing bin symlink (raw)" {
    rm "${ROOT}/bin"
    run_ir "y"
    [ -L "${ROOT}/bin" ]
    [ "$(readlink "${ROOT}/bin")" = "usr/bin" ]
}

@test "FSCK-IR-009: -r 'y' repairs wrong bin symlink target (raw)" {
    rm "${ROOT}/bin"
    ln -s "WRONG" "${ROOT}/bin"
    run_ir "y"
    [ "$(readlink "${ROOT}/bin")" = "usr/bin" ]
}

@test "FSCK-IR-010: -r 'y' repairs wrong lib symlink target (raw)" {
    rm "${ROOT}/lib"
    ln -s "WRONG" "${ROOT}/lib"
    run_ir "y"
    [ "$(readlink "${ROOT}/lib")" = "usr/lib" ]
}

@test "FSCK-IR-011: -r 'y' repairs wrong lib64 symlink target (raw)" {
    rm "${ROOT}/lib64"
    ln -s "WRONG" "${ROOT}/lib64"
    run_ir "y"
    [ "$(readlink "${ROOT}/lib64")" = "usr/lib64" ]
}

# ---------------------------------------------------------------------------
# -r: answer "n" -> NOT repaired, raw verify nothing changed
# ---------------------------------------------------------------------------

@test "FSCK-IR-012: -r 'n' does NOT repair missing usr (raw)" {
    rm -rf "${ROOT}/usr"
    run_ir "n"
    [ ! -d "${ROOT}/usr" ]
}

@test "FSCK-IR-013: -r 'n' sets bit 1 (error found, not repaired)" {
    rm -rf "${ROOT}/usr"
    run_ir "n"
    (( status & 1 ))
}

@test "FSCK-IR-014: -r empty answer (just newline) does NOT repair (raw)" {
    rm -rf "${ROOT}/usr"
    run_ir ""
    [ ! -d "${ROOT}/usr" ]
}

@test "FSCK-IR-015: -r 'n' does NOT repair missing bin symlink (raw)" {
    rm "${ROOT}/bin"
    run_ir "n"
    [ ! -L "${ROOT}/bin" ]
}

@test "FSCK-IR-016: -r 'n' leaves wrong lib target unchanged (raw)" {
    rm "${ROOT}/lib"
    ln -s "BADTARGET" "${ROOT}/lib"
    run_ir "n"
    [ "$(readlink "${ROOT}/lib")" = "BADTARGET" ]
}

# ---------------------------------------------------------------------------
# -r: selective repair -- some y, some n
# ---------------------------------------------------------------------------

@test "FSCK-IR-017: -r selective: usr=y, etc=n -> usr present, etc missing (raw)" {
    rm -rf "${ROOT}/usr" "${ROOT}/etc"
    # dirs are iterated: usr etc home proc dev tmp run opt var
    # usr gets first answer (y), etc gets second (n)
    run_ir $'y\nn'
    [ -d "${ROOT}/usr" ]
    [ ! -d "${ROOT}/etc" ]
}

@test "FSCK-IR-018: -r selective partial repair sets bits 1 and 2 (exit 3)" {
    rm -rf "${ROOT}/usr" "${ROOT}/etc"
    run_ir $'y\nn'
    (( status & 1 ))
    (( status & 2 ))
}

@test "FSCK-IR-019: -r all y: repairs all missing dirs (raw)" {
    rm -rf "${ROOT}/usr" "${ROOT}/etc" "${ROOT}/var"
    # 3 dirs missing -> need 3 y answers
    run_ir $'y\ny\ny'
    [ -d "${ROOT}/usr" ]
    [ -d "${ROOT}/etc" ]
    [ -d "${ROOT}/var" ]
}

@test "FSCK-IR-020: -r all n: repairs nothing (raw)" {
    rm -rf "${ROOT}/usr" "${ROOT}/etc" "${ROOT}/var"
    run_ir $'n\nn\nn'
    [ ! -d "${ROOT}/usr" ]
    [ ! -d "${ROOT}/etc" ]
    [ ! -d "${ROOT}/var" ]
}

# ---------------------------------------------------------------------------
# -r: output contains [PROMPT] text
# ---------------------------------------------------------------------------

@test "FSCK-IR-021: -r emits [PROMPT] for each repairable error" {
    rm -rf "${ROOT}/usr"
    run_ir "n"
    [[ "$output" == *"[PROMPT]"* ]]
}

@test "FSCK-IR-022: -r [PROMPT] text mentions the missing path" {
    rm -rf "${ROOT}/usr"
    run_ir "n"
    [[ "$output" == *"${ROOT}/usr"* ]]
}

# ---------------------------------------------------------------------------
# -r: after repair, clean fsck exits 0, raw verify
# ---------------------------------------------------------------------------

@test "FSCK-IR-023: after -r y repair, second fsck exits 0 (raw verify dir exists)" {
    rm -rf "${ROOT}/usr"
    run_ir "y"
    [ -d "${ROOT}/usr" ]
    run bash "$SCRIPT" fsck \
        --host-real-root    "$ROOT" \
        --virtual-user-name sandbox_user 2>&1
    [ "$status" -eq 0 ]
}

@test "FSCK-IR-024: after -r y repair of symlink, raw target is correct and second fsck exits 0" {
    rm "${ROOT}/bin"
    run_ir "y"
    [ "$(readlink "${ROOT}/bin")" = "usr/bin" ]
    run bash "$SCRIPT" fsck \
        --host-real-root    "$ROOT" \
        --virtual-user-name sandbox_user 2>&1
    [ "$status" -eq 0 ]
}
