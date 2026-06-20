#!/usr/bin/env bash
# leet-toml.sh — the single reader AND writer for ~/.leetcode/leetcode.toml (the single
# source of truth). Sourced by scripts/leet, scripts/leetcode-mcp, and scripts/setup.sh.
# Two layers: pure string helpers (toml_get/has/set, apply_lang_to_toml) that take content
# and hand it back, and the on-disk I/O seam (toml_load/store/set_keys) that owns reading,
# atomic writing, and the read-modify-write — so no caller hand-rolls a cat/printf dance.
# This module owns the on-disk format (quoting, indentation) so nothing else hand-rolls a regex.

# toml_path — canonical path to the leetcode.toml, overridable via $LEETCODE_TOML.
toml_path() {
    printf '%s\n' "${LEETCODE_TOML:-$HOME/.leetcode/leetcode.toml}"
}

# toml_get <content> <key> — first quoted value for key, or empty string.
toml_get() {
    local content="$1" key="$2"
    sed -nE "s/^[[:space:]]*${key}[[:space:]]*=[[:space:]]*['\"]([^'\"]*)['\"].*/\1/p" <<< "$content" | head -1
}

# toml_has <content> <key> — exit 0 if key is present with a non-empty value, else 1.
toml_has() {
    [ -n "$(toml_get "$1" "$2")" ]
}

# toml_set <content> <key> <value> — content with key's first quoted value
# replaced by <value>, preserving the existing quote character and indentation.
# Absent keys leave content unchanged (callers seed cookie keys via setup.sh).
# Values are cookie tokens / hostnames (no newlines), so a one-line sed is enough;
# we escape the sed-replacement metacharacters (\ & |) to stay literal.
toml_set() {
    local content="$1" key="$2" value="$3" esc
    esc=$(printf '%s' "$value" | sed -e 's/[\\&|]/\\&/g')
    sed -E "s|^([[:space:]]*${key}[[:space:]]*=[[:space:]]*)(['\"])[^'\"]*\2|\1\2${esc}\2|" <<< "$content"
}

# apply_lang_to_toml <content> <lang> <inject_before_toml> <comment_leading>
# Returns updated TOML content via stdout. Pure, testable. Owns the [code]-block
# quoting convention: lang single-quoted, comment_leading double-quoted, inject_before
# a raw array. Replaces those lines; adds comment_leading after lang if missing.
apply_lang_to_toml() {
    local content="$1" lang="$2" inject_before="$3" comment_leading="$4"
    printf '%s\n' "$content" | awk -v lang="$lang" -v inj="$inject_before" -v cl="$comment_leading" '
        /^[[:space:]]*lang[[:space:]]*=/ {
            printf "lang = \47%s\47\n", lang
            printf "comment_leading = \"%s\"\n", cl
            next
        }
        /^[[:space:]]*inject_before[[:space:]]*=/ {
            printf "inject_before = %s\n", inj
            next
        }
        /^[[:space:]]*comment_leading[[:space:]]*=/ {
            next
        }
        { print }
    '
}

# --- on-disk I/O (the deep read/write seam: callers no longer cat/printf by hand) ---

# toml_load <path> — print the file content. Returns non-zero (no output) when the
# file is missing, leaving the user-facing "run setup first" message to the caller.
toml_load() {
    [ -f "$1" ] || return 1
    cat "$1"
}

# toml_store <path> <content> — write <content> plus one trailing newline to <path>
# atomically: render into a temp file in the same directory, then mv it over the
# target. A crash mid-write can't truncate the single source of truth (which holds
# the only copy of the session cookie). Same-dir temp keeps the mv on one filesystem.
toml_store() {
    local path="$1" content="$2" tmp
    tmp=$(mktemp "$path.XXXXXX") || return 1
    if printf '%s\n' "$content" > "$tmp" && mv -f "$tmp" "$path"; then
        return 0
    fi
    rm -f "$tmp"
    return 1
}

# toml_set_keys <path> <key> <value> ... — read-modify-write each key/value pair
# into <path> in one atomic store. Pairs with an empty value are skipped, so a
# missing cookie never clobbers the stored one ("don't clobber" lives here, not in
# every caller). Absent keys are left unchanged (toml_set semantics).
toml_set_keys() {
    local path="$1"; shift
    local content key value
    content=$(toml_load "$path") || return 1
    while [ "$#" -ge 2 ]; do
        key="$1"; value="$2"; shift 2
        [ -n "$value" ] || continue
        content=$(toml_set "$content" "$key" "$value")
    done
    toml_store "$path" "$content"
}
