#!/usr/bin/env bash
# leet-languages.sh — shared registry: helix language name → leetcode-cli config.
# Sourced by both scripts/leet and scripts/setup.sh — single source of truth.
# Helix names match [[language]] entries in helix's languages.toml.

# Space-separated list of supported helix language names (for `select` and iteration)
SUPPORTED_LANGS="python rust cpp c java go"

# lang_info <helix_name> — sets LC_LANG, LC_INJECT_BEFORE, LC_COMMENT_LEADING.
# Returns 1 for unsupported languages.
lang_info() {
    LC_LANG="" LC_INJECT_BEFORE="" LC_COMMENT_LEADING=""
    case "$1" in
        python)
            LC_LANG="python3"
            LC_INJECT_BEFORE='["from typing import List, Optional, Dict, Set, Tuple"]'
            LC_COMMENT_LEADING="#"
            ;;
        rust)
            LC_LANG="rust"
            LC_INJECT_BEFORE="[]"
            LC_COMMENT_LEADING="//"
            ;;
        cpp)
            LC_LANG="cpp"
            LC_INJECT_BEFORE='["#include <vector>", "#include <string>", "#include <algorithm>", "using namespace std;"]'
            LC_COMMENT_LEADING="//"
            ;;
        c)
            LC_LANG="c"
            LC_INJECT_BEFORE='["#include <stdio.h>", "#include <stdlib.h>", "#include <string.h>"]'
            LC_COMMENT_LEADING="//"
            ;;
        java)
            LC_LANG="java"
            LC_INJECT_BEFORE='["import java.util.*;"]'
            LC_COMMENT_LEADING="//"
            ;;
        go)
            LC_LANG="go"
            LC_INJECT_BEFORE="[]"
            LC_COMMENT_LEADING="//"
            ;;
        *)
            return 1
            ;;
    esac
}

# current_lang <toml_content> — extracts the lang value (pure, testable)
current_lang() {
    sed -nE "s/^[[:space:]]*lang[[:space:]]*=[[:space:]]*['\"]([^'\"]*)['\"].*/\1/p" <<< "$1" | head -1
}

# apply_lang_to_toml <content> <lang> <inject_before_toml> <comment_leading>
# Returns updated TOML content via stdout. Pure, testable.
# Replaces lang/inject_before/comment_leading lines; adds comment_leading after lang if missing.
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
