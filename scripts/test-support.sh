#!/usr/bin/env bash
# test-support.sh — the single shared assertion harness for the *_test.sh suites.
# Owns the pass/fail tally, the assertion vocabulary, and the run summary, so no
# test file hand-rolls its own. Source it first; call finish last.
#
# Arithmetic uses pass=$((pass + 1)) (always a non-zero result) rather than
# ((pass++)) so the counters are safe under a caller's `set -e`.

pass=0
fail=0

# assert_eq <name> <actual> <expected>
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

# assert_succeeds <name> <cmd> [args...] — the command is expected to exit zero.
assert_succeeds() {
    local name="$1"; shift
    if "$@" >/dev/null 2>&1; then
        echo "PASS: $name"
        pass=$((pass + 1))
    else
        echo "FAIL: $name should succeed"
        fail=$((fail + 1))
    fi
}

# assert_fails <name> <cmd> [args...] — the command is expected to exit non-zero.
assert_fails() {
    local name="$1"; shift
    if "$@" >/dev/null 2>&1; then
        echo "FAIL: $name should fail"
        fail=$((fail + 1))
    else
        echo "PASS: $name"
        pass=$((pass + 1))
    fi
}

# finish — print the run summary and return non-zero if any assertion failed.
# Call it as the last line of a suite so its status becomes the suite's exit code.
finish() {
    echo ""
    echo "Results: $pass passed, $fail failed"
    [ "$fail" -eq 0 ]
}
