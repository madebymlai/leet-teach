#!/usr/bin/env bash
# Unit tests for scripts/leet-toml.sh pure helpers.
# Arrange-Act-Assert, one behavior per test, no logic in test bodies.
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=leet-toml.sh
source "$TESTS_DIR/leet-toml.sh"

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

# --- toml_get ---

test_toml_get_extracts_single_quoted_value() {
    local content val
    content=$'[cookies]\nsession = \'abc123secret\''
    val=$(toml_get "$content" "session")
    assert_eq "toml_get extracts single-quoted value" "$val" "abc123secret"
}

test_toml_get_extracts_double_quoted_value() {
    local content val
    content=$'[cookies]\nsession = "abc123secret"'
    val=$(toml_get "$content" "session")
    assert_eq "toml_get extracts double-quoted value" "$val" "abc123secret"
}

test_toml_get_tolerates_indentation_and_loose_spacing() {
    local content val
    content=$'[cookies]\n  session   =   \'abc123\''
    val=$(toml_get "$content" "session")
    assert_eq "toml_get tolerates indentation and loose spacing" "$val" "abc123"
}

test_toml_get_empty_value_returns_empty() {
    local content val
    content=$'[cookies]\nsession = \'\''
    val=$(toml_get "$content" "session")
    assert_eq "toml_get empty value returns empty" "$val" ""
}

test_toml_get_missing_key_returns_empty() {
    local content val
    content=$'[cookies]\ncsrf = \'abc\''
    val=$(toml_get "$content" "session")
    assert_eq "toml_get missing key returns empty" "$val" ""
}

test_toml_get_reads_only_the_named_key() {
    local content val
    content=$'[cookies]\ncsrf = \'CSRFTOKEN\'\nsession = \'SESSIONVALUE\''
    val=$(toml_get "$content" "session")
    assert_eq "toml_get reads only the named key (no cross-key bleed)" "$val" "SESSIONVALUE"
}

test_toml_get_returns_first_when_key_repeats() {
    local content val
    content=$'[code]\nlang = \'python3\'\nlang = \'rust\''
    val=$(toml_get "$content" "lang")
    assert_eq "toml_get returns first match when key repeats" "$val" "python3"
}

# --- toml_has ---

test_toml_has_true_for_nonempty_value() {
    local content
    content=$'[cookies]\nsession = \'abc123secret\''
    assert_succeeds "toml_has true for nonempty value" toml_has "$content" "session"
}

test_toml_has_false_for_empty_value() {
    local content
    content=$'[cookies]\nsession = \'\''
    assert_fails "toml_has false for empty value" toml_has "$content" "session"
}

test_toml_has_false_for_missing_key() {
    local content
    content=$'[cookies]\ncsrf = \'abc\''
    assert_fails "toml_has false for missing key" toml_has "$content" "session"
}

test_toml_has_true_for_double_quoted_value() {
    local content
    content=$'[cookies]\nsession = "abc123secret"'
    assert_succeeds "toml_has true for double-quoted value" toml_has "$content" "session"
}

test_toml_has_true_for_indented_key() {
    local content
    content=$'[cookies]\n  session = \'abc\''
    assert_succeeds "toml_has true for indented key" toml_has "$content" "session"
}

# --- run ---

test_toml_get_extracts_single_quoted_value
test_toml_get_extracts_double_quoted_value
test_toml_get_tolerates_indentation_and_loose_spacing
test_toml_get_empty_value_returns_empty
test_toml_get_missing_key_returns_empty
test_toml_get_reads_only_the_named_key
test_toml_get_returns_first_when_key_repeats
test_toml_has_true_for_nonempty_value
test_toml_has_false_for_empty_value
test_toml_has_false_for_missing_key
test_toml_has_true_for_double_quoted_value
test_toml_has_true_for_indented_key

echo ""
echo "Results: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
