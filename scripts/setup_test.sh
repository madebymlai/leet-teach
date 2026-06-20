#!/usr/bin/env bash
# Unit tests for scripts/setup.sh — the run_steps orchestrator and the SETUP_STEPS registry.
# Arrange-Act-Assert, one behavior per test, no logic in test bodies.
# The install/configure steps themselves are effectful and stay untested; run_steps is
# exercised with toy registries of fake step functions.
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=setup.sh
source "$TESTS_DIR/setup.sh"

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

# --- run_steps: green path ---

test_run_steps_runs_each_step_in_order_with_no_failures() {
    local failed=() ran=""
    _step_a() { ran="${ran}a"; }
    _step_b() { ran="${ran}b"; }
    run_steps failed "x:_step_a" "y:_step_b" >/dev/null
    assert_eq "run_steps dispatches each step's function in order" "$ran" "ab"
    assert_eq "run_steps reports no failures when all steps succeed" "${failed[*]}" ""
}

# --- run_steps: failure handling ---

test_run_steps_records_failed_label_and_continues() {
    local failed=() ran=""
    _step_fail() { ran="${ran}1"; return 1; }
    _step_ok()   { ran="${ran}2"; return 0; }
    run_steps failed "first:_step_fail" "second:_step_ok" >/dev/null
    assert_eq "run_steps collects the failed step's label" "${failed[*]}" "first"
    assert_eq "run_steps keeps running steps after a failure" "$ran" "12"
}

test_run_steps_collects_failures_in_registry_order() {
    local failed=()
    _step_ok()   { return 0; }
    _step_fail() { return 1; }
    run_steps failed "a:_step_fail" "b:_step_ok" "c:_step_fail" >/dev/null
    assert_eq "run_steps collects failed labels in registry order" "${failed[*]}" "a c"
}

# --- SETUP_STEPS registry contract ---

test_every_registered_step_resolves_to_a_defined_function() {
    local entry fn unresolved="" count=0
    for entry in "${SETUP_STEPS[@]+"${SETUP_STEPS[@]}"}"; do
        count=$((count + 1))
        fn=${entry#*:}
        declare -F "$fn" >/dev/null || unresolved="${unresolved} ${fn}"
    done
    assert_eq "SETUP_STEPS is non-empty" "$([ "$count" -gt 0 ] && echo yes || echo no)" "yes"
    assert_eq "every SETUP_STEPS entry maps to a defined function" "$unresolved" ""
}

# --- run ---

test_run_steps_runs_each_step_in_order_with_no_failures
test_run_steps_records_failed_label_and_continues
test_run_steps_collects_failures_in_registry_order
test_every_registered_step_resolves_to_a_defined_function

echo ""
echo "Results: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
