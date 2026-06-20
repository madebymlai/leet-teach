#!/usr/bin/env bash
# Unit tests for scripts/leet-cookies.sh.
# Pure helper (is_auth_failure) plus the sqlite read/sync exercised against
# synthetic Firefox moz_cookies fixtures (stdlib sqlite3 only — no browser needed).
# Arrange-Act-Assert, one behavior per test, no logic in test bodies.
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=leet-cookies.sh
source "$TESTS_DIR/leet-cookies.sh"
# shellcheck source=test-support.sh
source "$TESTS_DIR/test-support.sh"

# make_db <db-path> "name|value|host|lastAccessed"... — write a minimal Firefox
# cookies.sqlite holding just the columns cookies_read selects.
make_db() {
    local db="$1"; shift
    python3 - "$db" "$@" <<'PY'
import sqlite3, sys
con = sqlite3.connect(sys.argv[1])
con.execute("CREATE TABLE moz_cookies "
            "(id INTEGER PRIMARY KEY, name TEXT, value TEXT, host TEXT, lastAccessed INTEGER)")
for spec in sys.argv[2:]:
    name, value, host, la = spec.split("|")
    con.execute("INSERT INTO moz_cookies (name,value,host,lastAccessed) VALUES (?,?,?,?)",
                (name, value, host, int(la)))
con.commit(); con.close()
PY
}

# --- is_auth_failure (pure: exit code + output → re-sync decision) ---

test_auth_failure_on_expired_cookie_text() {
    assert_succeeds "is_auth_failure on 'cookies seems expired'" \
        is_auth_failure 1 "error: Your leetcode cookies seems expired, please make sure ..."
}

test_auth_failure_on_chrome_not_login_text() {
    assert_succeeds "is_auth_failure on ChromeNotLogin text" \
        is_auth_failure 1 "Maybe you not login on the Chrome, you can login and retry"
}

test_auth_failure_on_json_parse_text() {
    assert_succeeds "is_auth_failure on NoneError json-parse text" \
        is_auth_failure 1 "json from response parse failed, please open a new issue"
}

test_auth_failure_on_403_with_nonzero_exit() {
    assert_succeeds "is_auth_failure on 403 + non-zero exit" \
        is_auth_failure 1 "request failed: 403 Forbidden"
}

test_no_auth_failure_on_success() {
    assert_fails "no auth-failure on a clean success" \
        is_auth_failure 0 "Accepted    Runtime: 0 ms"
}

test_no_auth_failure_on_403_when_exit_zero() {
    assert_fails "no auth-failure when '403' appears but exit is 0" \
        is_auth_failure 0 "Test case output contained 403"
}

test_no_auth_failure_on_compile_error() {
    assert_fails "no auth-failure on a compile error" \
        is_auth_failure 1 "Compile Error: expected ';'"
}

# --- cookies_read (sqlite → session/csrf/site) ---

test_cookies_read_extracts_session_csrf_site() {
    local dir; dir=$(mktemp -d)
    make_db "$dir/c.sqlite" \
        "LEETCODE_SESSION|SESSVAL|.leetcode.com|100" \
        "csrftoken|CSRFVAL|leetcode.com|90"
    local fields=() s c site
    mapfile -t fields < <(cookies_read "$dir/c.sqlite")
    s="${fields[0]:-}"; c="${fields[1]:-}"; site="${fields[2]:-}"
    assert_eq "cookies_read session" "$s" "SESSVAL"
    assert_eq "cookies_read csrf" "$c" "CSRFVAL"
    assert_eq "cookies_read site global" "$site" "leetcode.com"
    rm -rf "$dir"
}

test_cookies_read_picks_freshest_profile() {
    local dir; dir=$(mktemp -d)
    make_db "$dir/old.sqlite" \
        "LEETCODE_SESSION|OLDSESS|.leetcode.com|100" "csrftoken|OLDCSRF|leetcode.com|100"
    make_db "$dir/new.sqlite" \
        "LEETCODE_SESSION|NEWSESS|.leetcode.com|200" "csrftoken|NEWCSRF|leetcode.com|200"
    local fields=() s c site
    mapfile -t fields < <(cookies_read "$dir/old.sqlite" "$dir/new.sqlite")
    s="${fields[0]:-}"; c="${fields[1]:-}"; site="${fields[2]:-}"
    assert_eq "freshest session wins" "$s" "NEWSESS"
    assert_eq "csrf comes from the freshest profile" "$c" "NEWCSRF"
    rm -rf "$dir"
}

test_cookies_read_detects_cn_site() {
    local dir; dir=$(mktemp -d)
    make_db "$dir/c.sqlite" "LEETCODE_SESSION|S|.leetcode.cn|100"
    local fields=() s c site
    mapfile -t fields < <(cookies_read "$dir/c.sqlite")
    s="${fields[0]:-}"; c="${fields[1]:-}"; site="${fields[2]:-}"
    assert_eq "cn host → leetcode.cn site" "$site" "leetcode.cn"
    rm -rf "$dir"
}

test_cookies_read_empty_when_no_leetcode_cookie() {
    local dir; dir=$(mktemp -d)
    make_db "$dir/c.sqlite" "sessionid|X|.example.com|100"
    local fields=() s c site
    mapfile -t fields < <(cookies_read "$dir/c.sqlite")
    s="${fields[0]:-}"; c="${fields[1]:-}"; site="${fields[2]:-}"
    assert_eq "no leetcode cookie → empty session" "$s" ""
    rm -rf "$dir"
}

test_cookies_read_session_without_csrf() {
    local dir; dir=$(mktemp -d)
    make_db "$dir/c.sqlite" "LEETCODE_SESSION|S|.leetcode.com|100"
    local fields=() s c site
    mapfile -t fields < <(cookies_read "$dir/c.sqlite")
    s="${fields[0]:-}"; c="${fields[1]:-}"; site="${fields[2]:-}"
    assert_eq "session present" "$s" "S"
    assert_eq "csrf empty when absent" "$c" ""
    rm -rf "$dir"
}

# --- cookies_sync (browser → leetcode.toml, via LEET_COOKIE_DBS seam) ---

seed_toml() {
    printf '%s\n' "[cookies]" "csrf = 'OLDCSRF'" "session = 'OLDSESS'" "site = 'leetcode.com'" > "$1"
}

test_cookies_sync_writes_session_and_csrf() {
    local dir; dir=$(mktemp -d)
    make_db "$dir/c.sqlite" \
        "LEETCODE_SESSION|NEWSESS|.leetcode.com|100" "csrftoken|NEWCSRF|leetcode.com|100"
    seed_toml "$dir/leetcode.toml"
    LEET_COOKIE_DBS="$dir/c.sqlite" cookies_sync "$dir/leetcode.toml" 2>/dev/null
    local content; content=$(cat "$dir/leetcode.toml")
    assert_eq "session written" "$(toml_get "$content" session)" "NEWSESS"
    assert_eq "csrf written" "$(toml_get "$content" csrf)" "NEWCSRF"
    rm -rf "$dir"
}

test_cookies_sync_keeps_existing_csrf_when_browser_has_none() {
    local dir; dir=$(mktemp -d)
    make_db "$dir/c.sqlite" "LEETCODE_SESSION|NEWSESS|.leetcode.com|100"
    seed_toml "$dir/leetcode.toml"
    LEET_COOKIE_DBS="$dir/c.sqlite" cookies_sync "$dir/leetcode.toml" 2>/dev/null
    local content; content=$(cat "$dir/leetcode.toml")
    assert_eq "session refreshed" "$(toml_get "$content" session)" "NEWSESS"
    assert_eq "stale csrf not clobbered with empty" "$(toml_get "$content" csrf)" "OLDCSRF"
    rm -rf "$dir"
}

test_cookies_sync_fails_and_preserves_toml_when_no_session() {
    local dir; dir=$(mktemp -d)
    make_db "$dir/c.sqlite" "sessionid|X|.example.com|100"
    seed_toml "$dir/leetcode.toml"
    LEET_COOKIE_DBS="$dir/c.sqlite" assert_fails "sync fails without a live session" \
        cookies_sync "$dir/leetcode.toml"
    local content; content=$(cat "$dir/leetcode.toml")
    assert_eq "toml session left intact on failure" "$(toml_get "$content" session)" "OLDSESS"
    rm -rf "$dir"
}

# --- run ---

test_auth_failure_on_expired_cookie_text
test_auth_failure_on_chrome_not_login_text
test_auth_failure_on_json_parse_text
test_auth_failure_on_403_with_nonzero_exit
test_no_auth_failure_on_success
test_no_auth_failure_on_403_when_exit_zero
test_no_auth_failure_on_compile_error
test_cookies_read_extracts_session_csrf_site
test_cookies_read_picks_freshest_profile
test_cookies_read_detects_cn_site
test_cookies_read_empty_when_no_leetcode_cookie
test_cookies_read_session_without_csrf
test_cookies_sync_writes_session_and_csrf
test_cookies_sync_keeps_existing_csrf_when_browser_has_none
test_cookies_sync_fails_and_preserves_toml_when_no_session

finish
