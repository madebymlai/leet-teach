#!/usr/bin/env bash
# Tests for scripts/run-tests — the suite runner (discovery, aggregation, exit).
# Uses the shared harness, and drives run-tests against throwaway fixture dirs so
# it never recurses into the real scripts/ directory.
set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=test-support.sh
source "$TESTS_DIR/test-support.sh"

RUNNER="$TESTS_DIR/run-tests"

# make_suite <dir> <name> <exit_code> — drop a trivial *_test.sh fixture.
make_suite() {
    local dir="$1" name="$2" code="$3"
    cat > "$dir/$name" <<EOF
#!/usr/bin/env bash
exit $code
EOF
}

# run_rc <dir> — run the runner on <dir>, echo its exit code (capture-safe under set -e).
run_rc() {
    if bash "$RUNNER" "$1" >/dev/null 2>&1; then echo 0; else echo $?; fi
}

# --- exit code: every suite passes → 0 ---

test_all_passing_exits_zero() {
    local dir; dir=$(mktemp -d)
    make_suite "$dir" "a_test.sh" 0
    assert_eq "all passing → exit 0" "$(run_rc "$dir")" "0"
    rm -rf "$dir"
}

# --- exit code: any failing suite → non-zero ---

test_a_failing_suite_exits_nonzero() {
    local dir; dir=$(mktemp -d)
    make_suite "$dir" "a_test.sh" 1
    assert_eq "one failing → exit 1" "$(run_rc "$dir")" "1"
    rm -rf "$dir"
}

# --- aggregation: a failure in non-last position is still caught and named ---

test_runs_all_suites_and_names_the_failed_one() {
    local dir out; dir=$(mktemp -d)
    make_suite "$dir" "a_test.sh" 1   # fails, and is not last alphabetically
    make_suite "$dir" "z_test.sh" 0
    assert_eq "mixed run → exit 1" "$(run_rc "$dir")" "1"
    out=$(bash "$RUNNER" "$dir" 2>&1)
    case "$out" in
        *"FAILED"*"a_test.sh"*) assert_eq "names the failed suite" "ok" "ok" ;;
        *) assert_eq "names the failed suite" "$out" "should mention FAILED a_test.sh" ;;
    esac
    rm -rf "$dir"
}

# --- discovery: only *_test.sh files are run ---

test_ignores_non_matching_files() {
    local dir; dir=$(mktemp -d)
    make_suite "$dir" "a_test.sh" 0
    make_suite "$dir" "broken.sh" 1        # would fail if run, but isn't a *_test.sh
    assert_eq "non-matching file ignored → exit 0" "$(run_rc "$dir")" "0"
    rm -rf "$dir"
}

# --- run ---

test_all_passing_exits_zero
test_a_failing_suite_exits_nonzero
test_runs_all_suites_and_names_the_failed_one
test_ignores_non_matching_files

finish
