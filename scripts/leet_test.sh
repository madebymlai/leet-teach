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

# --- session_is_set ---

test_session_is_set_accepts_nonempty_session() {
    local content
    content=$'[cookies]\nsession = \'abc123secret\''
    assert_succeeds "session_is_set accepts nonempty session" session_is_set "$content"
}

test_session_is_set_rejects_empty_session() {
    local content
    content=$'[cookies]\nsession = \'\''
    assert_fails "session_is_set rejects empty session" session_is_set "$content"
}

test_session_is_set_rejects_missing_session_key() {
    local content
    content=$'[cookies]\ncsrf = \'abc\''
    assert_fails "session_is_set rejects missing session key" session_is_set "$content"
}

test_session_is_set_accepts_double_quoted_session() {
    local content
    content=$'[cookies]\nsession = "abc123secret"'
    assert_succeeds "session_is_set accepts double-quoted session" session_is_set "$content"
}

test_session_is_set_accepts_indented_session_key() {
    local content
    content=$'[cookies]\n  session = \'abc\''
    assert_succeeds "session_is_set accepts indented session key" session_is_set "$content"
}

# --- run ---

test_parse_problem_id_extracts_first_bracketed_id
test_parse_problem_id_fails_without_bracketed_id
test_session_is_set_accepts_nonempty_session
test_session_is_set_rejects_empty_session
test_session_is_set_rejects_missing_session_key
test_session_is_set_accepts_double_quoted_session
test_session_is_set_accepts_indented_session_key

echo ""
echo "Results: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
