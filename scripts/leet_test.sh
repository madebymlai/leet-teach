#!/usr/bin/env bash
# Unit tests for scripts/leet pure helpers.
# Arrange-Act-Assert, one behavior per test, no logic in test bodies.
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=leet
source "$TESTS_DIR/leet"

pass=0
fail=0

assert_eq() {
    local name="$1" actual="$2" expected="$3"
    if [ "$actual" = "$expected" ]; then
        echo "PASS: $name"
        pass=$((pass + 1))
    else
        echo "FAIL: $name -- got '$actual', expected '$expected'"
        fail=$((fail + 1))
    fi
}

assert_succeeds() {
    local name="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        echo "PASS: $name"
        pass=$((pass + 1))
    else
        echo "FAIL: $name should succeed"
        fail=$((fail + 1))
    fi
}

assert_fails() {
    local name="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        echo "FAIL: $name should fail"
        fail=$((fail + 1))
    else
        echo "PASS: $name"
        pass=$((pass + 1))
    fi
}

# --- parse_problem_id ---

test_parse_problem_id_extracts_first_bracketed_id() {
    local output id
    output='[1] Two Sum    Easy
[2] Add Two Numbers    Medium'
    id=$(parse_problem_id "$output")
    assert_eq "parse_problem_id extracts first [N]" "$id" "1"
}

test_parse_problem_id_fails_without_bracketed_id() {
    local output
    output='Picked! Two Sum (Easy)'
    assert_fails "parse_problem_id fails without [N]" parse_problem_id "$output"
}

# Note: the session-cookie presence check (formerly session_is_set) now lives in
# scripts/leet-toml.sh as toml_has and is covered by leet-toml_test.sh.

# --- run ---

test_parse_problem_id_extracts_first_bracketed_id
test_parse_problem_id_fails_without_bracketed_id

echo ""
echo "Results: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
