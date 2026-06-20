#!/usr/bin/env bash
# leet-cookies.sh — pull the live LeetCode session/csrf out of a Firefox-family
# browser and sync them into ~/.leetcode/leetcode.toml (the single source of truth).
#
# Why this exists: leetcode-cli's `data -c` browser auto-fetch is unreliable, and
# sessions go *stale* (not empty) every couple of weeks. Firefox forks all store
# cookies UNENCRYPTED in a sqlite `moz_cookies` table, so we read them with Python's
# stdlib sqlite3 — no browser_cookie3, no pip dependency, no Chrome-style decryption.
#
# Works for any Firefox-family browser (Firefox, LibreWolf, Floorp, Zen, Waterfox,
# Mullvad, ...): we scan every known profile root for a cookies.sqlite that holds a
# leetcode.com LEETCODE_SESSION and take the freshest one.
#
# The decision helper (is_auth_failure) is pure and unit-tested; the sqlite read is
# thin I/O. Sourced by scripts/leet and scripts/leetcode-mcp.

LEET_COOKIES_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
# shellcheck source=leet-toml.sh
source "$LEET_COOKIES_DIR/leet-toml.sh"

# --- pure helpers (no I/O, testable) ---

# is_auth_failure <exit_code> <output> — true (0) when a leetcode-cli invocation
# failed because the session/csrf is stale, so callers should re-sync and retry.
# Matches clearloop leetcode-cli's CookieError / ChromeNotLogin / NoneError display
# text (see its src/err.rs) plus bare 401/403 on a non-zero exit. Case-insensitive.
is_auth_failure() {
    local code="$1" out="$2" low
    low=$(printf '%s' "$out" | tr '[:upper:]' '[:lower:]')
    case "$low" in
        *"cookies seems expired"*)            return 0 ;;  # CookieError
        *"not login on the chrome"*)          return 0 ;;  # ChromeNotLogin
        *"json from response parse failed"*)  return 0 ;;  # NoneError (login HTML, not JSON)
        *"login expired"*|*"please login"*)   return 0 ;;
    esac
    # Generic HTTP auth rejections only count when the command itself failed,
    # so a problem whose text happens to contain "403" can't trigger a false retry.
    if [ "${code:-0}" -ne 0 ]; then
        case "$low" in
            *401*|*403*|*unauthorized*|*forbidden*) return 0 ;;
        esac
    fi
    return 1
}

# leet_cookie_roots — profile roots where a Firefox-family browser may keep its
# cookies.sqlite. We glob *under* each (not a fixed profile name) so any fork or
# extra profile is picked up automatically. New forks: add a root here.
leet_cookie_roots() {
    cat <<EOF
$HOME/.mozilla/firefox
$HOME/.config/mozilla/firefox
$HOME/.librewolf
$HOME/.config/librewolf
$HOME/.config/librewolf/librewolf
$HOME/.floorp
$HOME/.config/floorp
$HOME/.config/zen
$HOME/.zen
$HOME/.waterfox
$HOME/.config/waterfox
$HOME/.mullvad-browser
$HOME/.config/mullvad-browser
$HOME/snap/firefox/common/.mozilla/firefox
$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox
$HOME/.var/app/io.gitlab.librewolf-community/.librewolf
$HOME/.var/app/one.ablaze.floorp/.floorp
$HOME/.var/app/app.zen_browser.zen/.zen
EOF
}

# --- I/O ---

# cookies_read <db-path...> — print session, csrf, site on three separate lines,
# read from the freshest Firefox-family profile that holds a leetcode LEETCODE_SESSION.
# One field per line (not tab-separated) so an empty middle field can't collapse into
# its neighbour. Fields are empty when absent; callers must not clobber a stored value.
cookies_read() {
    python3 - "$@" <<'PY'
import sqlite3, sys, tempfile, shutil, os

def rows_for(db):
    # Copy the db AND its WAL/SHM sidecars to a throwaway dir, then open the copy
    # read-write so SQLite replays the WAL. Freshly-set cookies (e.g. a rotated
    # csrftoken) often live in the not-yet-checkpointed WAL; reading the bare .sqlite
    # (or opening immutable) would miss them. Copying also avoids locking the browser.
    tmp = tempfile.mkdtemp()
    try:
        base = os.path.join(tmp, "c.sqlite")
        shutil.copy(db, base)
        for ext in ("-wal", "-shm"):
            if os.path.exists(db + ext):
                shutil.copy(db + ext, base + ext)
        con = sqlite3.connect(base)
        try:
            return con.execute(
                "SELECT name, value, host, lastAccessed FROM moz_cookies "
                "WHERE host LIKE '%leetcode%' "
                "AND name IN ('LEETCODE_SESSION','csrftoken')").fetchall()
        finally:
            con.close()
    except Exception:
        return []
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

best = None            # freshest session: (lastAccessed, value, db, host)
csrf_by_db = {}        # db -> (lastAccessed, value) freshest csrftoken in that profile
for db in sys.argv[1:]:
    for name, value, host, la in rows_for(db):
        la = la or 0
        if name == "LEETCODE_SESSION":
            if best is None or la > best[0]:
                best = (la, value, db, host)
        elif name == "csrftoken":
            cur = csrf_by_db.get(db)
            if cur is None or la > cur[0]:
                csrf_by_db[db] = (la, value)

session = csrf = site = ""
if best:
    session = best[1]
    site = "leetcode.cn" if "leetcode.cn" in best[3] else "leetcode.com"
    c = csrf_by_db.get(best[2])          # take csrf from the same profile as the session
    if c:
        csrf = c[1]

print(session)
print(csrf)
print(site)
PY
}

# cookies_db_list — newline-separated cookies.sqlite paths to read, de-duplicated
# (overlapping roots can resolve to the same profile). Honors an explicit
# LEET_COOKIE_DBS override (':'-separated; also the test seam); otherwise discovers
# them under leet_cookie_roots.
cookies_db_list() {
    {
        if [ -n "${LEET_COOKIE_DBS:-}" ]; then
            printf '%s\n' "${LEET_COOKIE_DBS//:/$'\n'}"
        else
            local root
            while IFS= read -r root; do
                [ -d "$root" ] || continue
                find "$root" -maxdepth 3 -name cookies.sqlite 2>/dev/null
            done < <(leet_cookie_roots)
        fi
    } | awk 'NF && !seen[$0]++'
}

# cookies_sync [toml_path] — read the live cookie from the browser and write it
# into leetcode.toml. Status goes to stderr (so MCP's stdout stays protocol-clean).
# Returns non-zero (and writes nothing) when no live session can be found.
cookies_sync() {
    local toml="${1:-$HOME/.leetcode/leetcode.toml}"
    [ -f "$toml" ] || { echo "leet sync: $toml not found. Run scripts/setup.sh first." >&2; return 1; }

    local dbs=() db
    while IFS= read -r db; do [ -n "$db" ] && dbs+=("$db"); done < <(cookies_db_list)
    [ "${#dbs[@]}" -gt 0 ] || {
        echo "leet sync: no Firefox-family browser profile found." >&2
        echo "  Log into https://leetcode.com in your browser, then run: leet sync" >&2
        return 1
    }

    local fields=() session csrf site
    mapfile -t fields < <(cookies_read "${dbs[@]}")
    session="${fields[0]:-}"; csrf="${fields[1]:-}"; site="${fields[2]:-}"
    [ -n "$session" ] || {
        echo "leet sync: no live leetcode session in any browser profile." >&2
        echo "  Log into https://leetcode.com in your browser, then run: leet sync" >&2
        return 1
    }

    # One atomic read-modify-write through the leet-toml seam. session is non-empty
    # (checked above); toml_set_keys skips empty csrf/site so a missing token never
    # clobbers the stored one.
    toml_set_keys "$toml" session "$session" csrf "$csrf" site "$site"

    echo "leet sync: session updated (${#session} chars)${csrf:+, csrf updated}, site=$site" >&2
}
