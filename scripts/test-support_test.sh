#!/usr/bin/env bash
# Bootstrap tests for scripts/test-support.sh — the shared assertion harness.
# This is the ONE suite that cannot use test-support.sh: it IS the system under
# test, so it rolls its own minimal check() with raw primitives. A broken harness
# must not be able to mask its own bug (e.g. an inverted assert_fails).
set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=test-support.sh
source "$TESTS_DIR/test-support.sh"

b_pass=0 b_fail=0
check() {  # check <name> <actual> <expected>
    if [ "$2" = "$3" ]; then echo "ok: $1"; b_pass=$((b_pass + 1))
    else echo "BAD: $1 -- got '$2' want '$3'"; b_fail=$((b_fail + 1)); fi
}

# --- assert_eq: equal values count as a pass ---

test_assert_eq_equal_counts_pass() {
    check "assert_eq equal → pass=1 fail=0" \
        "$( pass=0; fail=0; assert_eq n a a >/dev/null; echo "$pass $fail" )" "1 0"
}

# --- assert_eq: unequal values count as a fail and name got/expected ---

test_assert_eq_unequal_counts_fail() {
    check "assert_eq unequal → pass=0 fail=1" \
        "$( pass=0; fail=0; assert_eq n a b >/dev/null; echo "$pass $fail" )" "0 1"
}

test_assert_eq_unequal_message_names_got_and_expected() {
    check "assert_eq unequal message" \
        "$( pass=0; fail=0; assert_eq lbl a b )" "FAIL: lbl -- got 'a', expected 'b'"
}

# --- assert_fails: a command that fails is the pass case (inversion risk) ---

test_assert_fails_counts_failing_command_as_pass() {
    check "assert_fails false → pass=1 fail=0" \
        "$( pass=0; fail=0; assert_fails n false >/dev/null; echo "$pass $fail" )" "1 0"
}

test_assert_fails_counts_succeeding_command_as_fail() {
    check "assert_fails true → pass=0 fail=1" \
        "$( pass=0; fail=0; assert_fails n true >/dev/null; echo "$pass $fail" )" "0 1"
}

# --- assert_succeeds: a command that succeeds is the pass case ---

test_assert_succeeds_counts_succeeding_command_as_pass() {
    check "assert_succeeds true → pass=1 fail=0" \
        "$( pass=0; fail=0; assert_succeeds n true >/dev/null; echo "$pass $fail" )" "1 0"
}

test_assert_succeeds_counts_failing_command_as_fail() {
    check "assert_succeeds false → pass=0 fail=1" \
        "$( pass=0; fail=0; assert_succeeds n false >/dev/null; echo "$pass $fail" )" "0 1"
}

# --- finish: exit code reflects failures; the tally is printed ---

test_finish_returns_zero_when_no_failures() {
    check "finish (fail=0) → exit 0" \
        "$( pass=2; fail=0; if finish >/dev/null; then echo 0; else echo 1; fi )" "0"
}

test_finish_returns_nonzero_when_any_failure() {
    check "finish (fail=1) → exit 1" \
        "$( pass=2; fail=1; if finish >/dev/null; then echo 0; else echo 1; fi )" "1"
}

test_finish_prints_the_tally() {
    check "finish prints tally" \
        "$( pass=3; fail=2; finish | tail -1 )" "Results: 3 passed, 2 failed"
}

# --- run ---

test_assert_eq_equal_counts_pass
test_assert_eq_unequal_counts_fail
test_assert_eq_unequal_message_names_got_and_expected
test_assert_fails_counts_failing_command_as_pass
test_assert_fails_counts_succeeding_command_as_fail
test_assert_succeeds_counts_succeeding_command_as_pass
test_assert_succeeds_counts_failing_command_as_fail
test_finish_returns_zero_when_no_failures
test_finish_returns_nonzero_when_any_failure
test_finish_prints_the_tally

echo ""
echo "bootstrap: $b_pass ok, $b_fail bad"
[ "$b_fail" -eq 0 ]
