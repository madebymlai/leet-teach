#!/usr/bin/env bash
# leet-languages.sh — shared registry: helix language name → leetcode-cli config.
# Sourced by both scripts/leet and scripts/setup.sh — single source of truth.
# Helix names match [[language]] entries in helix's languages.toml.

# Space-separated list of supported helix language names (for `select` and iteration)
# shellcheck disable=SC2034  # consumed by leet/setup.sh after sourcing
SUPPORTED_LANGS="python rust cpp c java go"

# lang_info <helix_name> — print one tab record "lang<TAB>inject_before<TAB>comment_leading"
# for the language on stdout, or return 1 if unsupported. Callers parse it explicitly:
#   IFS=$'\t' read -r lang inject comment <<< "$(lang_info "$name")"
lang_info() {
    local lang inject comment
    case "$1" in
        python)
            lang="python3"
            inject='["from typing import List, Optional, Dict, Set, Tuple"]'
            comment="#"
            ;;
        rust)
            lang="rust"
            inject="[]"
            comment="//"
            ;;
        cpp)
            lang="cpp"
            inject='["#include <vector>", "#include <string>", "#include <algorithm>", "using namespace std;"]'
            comment="//"
            ;;
        c)
            lang="c"
            inject='["#include <stdio.h>", "#include <stdlib.h>", "#include <string.h>"]'
            comment="//"
            ;;
        java)
            lang="java"
            inject='["import java.util.*;"]'
            comment="//"
            ;;
        go)
            lang="go"
            inject="[]"
            comment="//"
            ;;
        *)
            return 1
            ;;
    esac
    printf '%s\t%s\t%s\n' "$lang" "$inject" "$comment"
}

# Reading the current lang out of leetcode.toml lives in scripts/leet-toml.sh
# (toml_get); applying a language to the file lives there too (apply_lang_to_toml).
