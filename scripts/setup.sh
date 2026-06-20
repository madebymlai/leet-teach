#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# Pinned versions (bump when upgrading)
SKILLS_VERSION="latest"

PROJ_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=leet-languages.sh
source "$PROJ_DIR/scripts/leet-languages.sh"
# shellcheck source=leet-mcp.sh
source "$PROJ_DIR/scripts/leet-mcp.sh"
# shellcheck source=leet-toml.sh
source "$PROJ_DIR/scripts/leet-toml.sh"

# TTY-guarded colors
if [ -t 1 ]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
    BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; NC=''
fi

info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
die()   { err "$*"; exit 1; }

check_cmd() {
    if command -v "$1" &>/dev/null; then
        ok "$1 found: $(command -v "$1")"
        return 0
    fi
    warn "$1 not found"
    return 1
}

install_helix() {
    info "Checking for helix editor..."
    if command -v hx &>/dev/null; then
        ok "helix already installed: $(command -v hx)"
        return 0
    fi
    if command -v helix &>/dev/null; then
        ok "helix already installed: $(command -v helix)"
        if [ ! -e "$HOME/.local/bin/hx" ]; then
            info "Creating hx symlink -> helix..."
            mkdir -p "$HOME/.local/bin"
            ln -sf "$(command -v helix)" "$HOME/.local/bin/hx"
            ok "Created $HOME/.local/bin/hx -> $(command -v helix)"
        fi
        return 0
    fi
    err "helix (hx/helix) not found."
    echo ""
    echo "Install helix before running this script:"
    echo "  brew install helix"
    echo "  cargo install helix-term"
    echo "  sudo pacman -S helix"
    echo "  sudo dnf install helix"
    echo "  https://github.com/helix-editor/helix/releases"
    return 1
}

configure_helix() {
    info "Configuring helix for LeetCode..."
    local HELIX_CONFIG_DIR="$HOME/.config/helix"
    mkdir -p "$HELIX_CONFIG_DIR"

    if ! grep -q "# leet-teach-config" "$HELIX_CONFIG_DIR/config.toml" 2>/dev/null; then
        if [ -f "$HELIX_CONFIG_DIR/config.toml" ]; then
            warn "Backing up existing helix config.toml"
            cp "$HELIX_CONFIG_DIR/config.toml" "$HELIX_CONFIG_DIR/config.toml.bak"
        fi
        cat > "$HELIX_CONFIG_DIR/config.toml" << 'HELIXCONFIG'
# leet-teach-config
[editor]
line-number = "relative"
mouse = true
scroll-off = 5
color-modes = true

[editor.cursor-shape]
insert = "bar"
normal = "block"
select = "underline"

[editor.file-picker]
hidden = false

[editor.statusline]
left = ["mode", "spinner", "file-name", "file-modification-indicator"]
right = ["diagnostics", "selections", "position", "file-encoding"]
mode.normal = "NORMAL"
mode.insert = "INSERT"

[editor.lsp]
display-messages = true
auto-signature-help = true
display-inlay-hints = true
HELIXCONFIG
        ok "helix config written to $HELIX_CONFIG_DIR/config.toml"
    else
        info "helix config.toml already managed by leet-teach, skipping"
    fi

    if ! grep -q "# leet-teach-languages" "$HELIX_CONFIG_DIR/languages.toml" 2>/dev/null; then
        cat > "$HELIX_CONFIG_DIR/languages.toml" << 'LANGSCONFIG'
# leet-teach-languages
[language-server.pyright]
command = "pyright-langserver"
args = ["--stdio"]

[language-server.rust-analyzer]
command = "rust-analyzer"

[language-server.clangd]
command = "clangd"

[language-server.jdtls]
command = "jdtls"

[language-server.gopls]
command = "gopls"

[language-server.dart-language-server]
command = "dart"
args = ["language-server", "--client-id", "helix"]

[[language]]
name = "python"
language-servers = ["pyright"]
formatter = { command = "black", args = ["-"] }
auto-format = true

[[language]]
name = "rust"
language-servers = ["rust-analyzer"]

[[language]]
name = "c"
language-servers = ["clangd"]

[[language]]
name = "cpp"
language-servers = ["clangd"]

[[language]]
name = "java"
language-servers = ["jdtls"]

[[language]]
name = "go"
language-servers = ["gopls"]

[[language]]
name = "dart"
language-servers = ["dart-language-server"]
LANGSCONFIG
        ok "helix languages.toml written"
    else
        info "helix languages.toml already managed by leet-teach, skipping"
    fi
}

configure_tmux() {
    info "Configuring tmux..."
    local TMUX_CONFIG="$HOME/.tmux.conf"
    touch "$TMUX_CONFIG"

    if ! grep -q "set -g mouse on" "$TMUX_CONFIG" 2>/dev/null; then
        {
            echo ""
            echo "# leet-teach: enable mouse"
            echo "set -g mouse on"
        } >> "$TMUX_CONFIG"
        ok "tmux mouse enabled"
    else
        info "tmux mouse already enabled"
    fi

    if ! grep -q "Alt-Up" "$TMUX_CONFIG" 2>/dev/null; then
        {
            echo ""
            echo "# leet-teach: Alt+arrow pane switching"
            echo 'bind -n M-Up select-pane -U'
            echo 'bind -n M-Down select-pane -D'
            echo 'bind -n M-Left select-pane -L'
            echo 'bind -n M-Right select-pane -R'
        } >> "$TMUX_CONFIG"
        ok "Alt+arrow pane switching configured"
    else
        info "Alt+arrow pane switching already configured"
    fi

    if [ -n "${TMUX:-}" ]; then
        if tmux source-file "$TMUX_CONFIG" 2>/dev/null; then
            ok "tmux config reloaded"
        else
            warn "Could not reload tmux config (applies on next session)"
        fi
    fi
}

install_leetcode_cli() {
    info "Installing leetcode-cli (clearloop)..."
    if check_cmd leetcode; then
        info "leetcode-cli already installed, skipping"
        return 0
    fi
    if ! check_cmd cargo; then
        info "cargo not found, installing rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        # shellcheck source=/dev/null  # created by rustup at runtime
        source "$HOME/.cargo/env"
    fi
    cargo install leetcode-cli
    check_cmd leetcode || die "failed to install leetcode-cli. Install manually: cargo install leetcode-cli"
    ok "leetcode-cli installed successfully"
}

configure_leetcode_cli() {
    info "Configuring leetcode-cli..."
    local LC_DIR="$HOME/.leetcode"
    local toml bak
    toml=$(toml_path); bak="$toml.bak"
    mkdir -p "$LC_DIR"

    if grep -q "# leet-teach-config" "$toml" 2>/dev/null; then
        info "leetcode.toml already managed by leet-teach, skipping"
        info "Change language with: leet lang <name>"
        info "Edit ~/.leetcode/leetcode.toml for other settings"
        return 0
    fi

    if [ -f "$toml" ]; then
        warn "Backing up existing leetcode.toml"
        cp "$toml" "$bak"
    fi

    # Preserve existing session/csrf/site from old config (if any)
    local existing_session="" existing_csrf="" existing_site="leetcode.com"
    if [ -f "$bak" ]; then
        local bak_content
        bak_content=$(cat "$bak")
        existing_session=$(toml_get "$bak_content" session)
        existing_csrf=$(toml_get "$bak_content" csrf)
        existing_site=$(toml_get "$bak_content" site)
    fi

    local editor_cmd
    if command -v hx &>/dev/null; then
        editor_cmd="hx"
    elif command -v helix &>/dev/null; then
        editor_cmd="helix"
    elif [ -n "${EDITOR:-}" ]; then
        editor_cmd="$EDITOR"
    else
        die "no editor found. Set \$EDITOR or install helix before running setup."
    fi

    info "Choose your preferred language (default: python)"
    info "Supported: ${SUPPORTED_LANGS}"
    local chosen="python"
    if [ -t 0 ]; then
        read -rp "Language [python]: " chosen
        chosen="${chosen:-python}"
    fi
    local rec lc_lang lc_inject lc_comment
    rec=$(lang_info "$chosen") || die "unsupported language: $chosen. Supported: $SUPPORTED_LANGS"
    IFS=$'\t' read -r lc_lang lc_inject lc_comment <<< "$rec"

    # Render the fresh file with placeholder lang fields, then let apply_lang_to_toml
    # fill them in — so the [code]-block quoting lives in one place (leet-toml.sh) and
    # a fresh setup file stays byte-consistent with what `leet lang` later produces.
    local base
    base=$(cat << LEETCODECONFIG
# leet-teach-config
[code]
editor = '${editor_cmd}'
lang = ''
edit_code_marker = true
comment_problem_desc = true
inject_before = []
inject_after = []
test = true

[cookies]
csrf = '${existing_csrf}'
session = '${existing_session}'
site = '${existing_site}'

[storage]
cache = 'Problems'
code = 'code'
root = '~/.leetcode'
scripts = 'scripts'
LEETCODECONFIG
)
    toml_store "$toml" "$(apply_lang_to_toml "$base" "$lc_lang" "$lc_inject" "$lc_comment")"

    ok "leetcode-cli config written to $toml (lang: $chosen)"
    info "Change language later with: leet lang <name>"
    info "Set your cookies by logging into leetcode.com in your browser, then: leet sync"
}

install_mcp_server() {
    info "Setting up leetcode-mcp-server..."
    if check_cmd npx; then
        ok "npx found, MCP server will run via npx"
        return 0
    fi
    warn "npx not found. Installing Node.js..."
    if check_cmd brew; then
        brew install node
    elif check_cmd apt-get; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
    elif check_cmd pacman; then
        sudo pacman -S --noconfirm nodejs npm
    else
        die "no supported package manager found (brew/apt/pacman). Install Node.js manually: https://nodejs.org/"
    fi
    export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
    check_cmd npx || die "npx still not found after Node.js install. Install manually: https://nodejs.org/"
    ok "npx available, MCP server will run via npx"
}

install_mcp_launcher() {
    info "Installing leetcode-mcp launcher..."
    mkdir -p "$HOME/.local/bin"
    local launcher_dst="$HOME/.local/bin/leetcode-mcp"
    # Symlink (not copy) so the launcher can source scripts/leet-toml.sh at runtime,
    # mirroring how `leet` is installed.
    ln -sf "$PROJ_DIR/scripts/leetcode-mcp" "$launcher_dst"
    ok "launcher symlinked to $launcher_dst"
}

install_leet() {
    info "Installing leet command..."
    mkdir -p "$HOME/.local/bin"
    ln -sf "$PROJ_DIR/scripts/leet" "$HOME/.local/bin/leet"
    ok "leet symlinked to $HOME/.local/bin/leet"
}

configure_mcp() {
    info "Configuring project-local MCP for Claude Code, Codex, and OpenCode..."
    command -v python3 >/dev/null || die "python3 required to merge MCP configs"
    local launcher="$HOME/.local/bin/leetcode-mcp"
    [ -x "$launcher" ] || die "launcher not installed at $launcher. Run setup with mcp-launcher step."

    # Project-local scope: each assistant's config is written inside this folder so the
    # leetcode MCP server is only active for assistants launched from here — never
    # registered globally. The set of assistants and their project-scope paths lives
    # once in MCP_ASSISTANTS (scripts/leet-mcp.sh); we iterate it and dispatch the write
    # by kind via mcp_write, so adding an assistant is one registry row, not edits here.
    local row name kind live path
    for row in "${MCP_ASSISTANTS[@]}"; do
        IFS=: read -r name kind live _ <<< "$row"
        path="$PROJ_DIR/$live"
        mkdir -p "$(dirname "$path")"
        mcp_backup_once "$path"
        mcp_write "$kind" "$path" "$name" "$launcher"
        ok "$name MCP config written to $path (project scope)"
    done

    info ""
    info "These configs live inside the project. Launch your assistant from $PROJ_DIR."
    info "Codex: trust this folder when it prompts."
    warn "IMPORTANT: log into leetcode.com in your browser, then run: leet sync"
    info "  leet sync pulls the live session from any Firefox-family browser into"
    info "  ~/.leetcode/leetcode.toml. Both leetcode-cli and the MCP server read from"
    info "  there, and 'leet test/submit' auto-re-syncs when the session goes stale."
}

install_skill() {
    local repo="$1" name="$2"
    info "Installing $name skill from $repo..."
    npx "skills@${SKILLS_VERSION}" add "$repo" --skill "$name" -y \
        || die "failed to install $name skill from $repo"
}

install_skills() {
    info "Installing skills (mattpocock/teach + local leet-teach skill)..."
    cd "$PROJ_DIR"
    command -v npx >/dev/null || die "npx not found. Install Node.js first: https://nodejs.org/"
    install_skill mattpocock/skills teach
    install_skill madebymlai/leet-teach leet-teach
    ok "Skills setup complete"
}

setup_project() {
    info "Setting up project workspace..."
    mkdir -p "$PROJ_DIR"/{lessons,learning-records,reference}
    ok "Project directories created"
}

# SETUP_STEPS — the ordered registry of setup steps: one "label:function" entry each,
# in run order. Single source of truth (no parallel array + case to drift out of sync).
SETUP_STEPS=(
    "helix:install_helix"
    "helix-config:configure_helix"
    "tmux-config:configure_tmux"
    "leetcode-cli:install_leetcode_cli"
    "leetcode-config:configure_leetcode_cli"
    "mcp-install:install_mcp_server"
    "mcp-launcher:install_mcp_launcher"
    "leet:install_leet"
    "mcp-config:configure_mcp"
    "skills:install_skills"
    "project:setup_project"
)

# run_steps <out_array> <entry...> — run each "label:fn" entry in order. Dispatches
# the function by name; appends the label of any failed step to <out_array> (nameref).
run_steps() {
    local -n __out=$1; shift
    local entry label fn
    for entry in "$@"; do
        label=${entry%%:*}
        fn=${entry#*:}
        echo ""
        info "=== Step: $label ==="
        "$fn" || __out+=("$label")
    done
}

main() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════╗"
    echo "║       leet-teach setup                   ║"
    echo "║  helix + leetcode-cli + MCP + skills     ║"
    echo "╚══════════════════════════════════════════╝"
    echo -e "${NC}"

    local failed=()
    run_steps failed "${SETUP_STEPS[@]}"

    echo ""
    echo -e "${CYAN}════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Setup Complete!${NC}"
    echo -e "${CYAN}════════════════════════════════════════════${NC}"

    if [ ${#failed[@]} -gt 0 ]; then
        warn "Some steps failed: ${failed[*]}"
        warn "Re-run or install manually"
    fi

    echo ""
    echo -e "${GREEN}Quick start:${NC}"
    echo "  1. Log into leetcode.com in your browser, then:  leet sync"
    echo "  2. Pick a problem:             leet pick two-sum"
    echo "  3. Edit in helix:              leet edit 1"
    echo "  4. Test:                       leet test 1"
    echo "  5. Submit:                     leet submit 1"
    echo ""
    echo -e "${YELLOW}Or let your AI coach handle it via MCP tools.${NC}"
}

# Run only when executed, not when sourced (for tests).
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
