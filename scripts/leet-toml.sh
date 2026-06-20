#!/usr/bin/env bash
# leet-toml.sh — the single reader for ~/.leetcode/leetcode.toml (the single source of truth).
# Sourced by scripts/leet, scripts/leetcode-mcp, and scripts/setup.sh.
# Pure helpers, no I/O — callers cat the file and pass the content in.
# This module owns the on-disk format (quoting, indentation) so nothing else hand-rolls a regex.

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
