#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# Pinned versions (bump when upgrading)
SKILLS_VERSION="latest"
MCP_SERVER_VERSION="latest"
MCP_SERVER_PACKAGE="@jinzcdev/leetcode-mcp-server"
MCP_SITE="global"

PROJ_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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
        echo "" >> "$TMUX_CONFIG"
        echo "# leet-teach: enable mouse" >> "$TMUX_CONFIG"
        echo "set -g mouse on" >> "$TMUX_CONFIG"
        ok "tmux mouse enabled"
    else
        info "tmux mouse already enabled"
    fi

    if ! grep -q "Alt-Up" "$TMUX_CONFIG" 2>/dev/null; then
        echo "" >> "$TMUX_CONFIG"
        echo "# leet-teach: Alt+arrow pane switching" >> "$TMUX_CONFIG"
        echo 'bind -n M-Up select-pane -U' >> "$TMUX_CONFIG"
        echo 'bind -n M-Down select-pane -D' >> "$TMUX_CONFIG"
        echo 'bind -n M-Left select-pane -L' >> "$TMUX_CONFIG"
        echo 'bind -n M-Right select-pane -R' >> "$TMUX_CONFIG"
        ok "Alt+arrow pane switching configured"
    else
        info "Alt+arrow pane switching already configured"
    fi

    if [ -n "${TMUX:-}" ]; then
        tmux source-file "$TMUX_CONFIG" 2>/dev/null && ok "tmux config reloaded" || warn "Could not reload tmux config (applies on next session)"
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
        source "$HOME/.cargo/env"
    fi
    cargo install leetcode-cli
    check_cmd leetcode || die "failed to install leetcode-cli. Install manually: cargo install leetcode-cli"
    ok "leetcode-cli installed successfully"
}

configure_leetcode_cli() {
    info "Configuring leetcode-cli..."
    local LC_DIR="$HOME/.leetcode"
    mkdir -p "$LC_DIR"

    if grep -q "# leet-teach-config" "$LC_DIR/leetcode.toml" 2>/dev/null; then
        info "leetcode.toml already managed by leet-teach, skipping"
        info "Edit ~/.leetcode/leetcode.toml to change language/editor"
        return 0
    fi

    if [ -f "$LC_DIR/leetcode.toml" ]; then
        warn "Backing up existing leetcode.toml"
        cp "$LC_DIR/leetcode.toml" "$LC_DIR/leetcode.toml.bak"
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

    cat > "$LC_DIR/leetcode.toml" << LEETCODECONFIG
# leet-teach-config
[code]
editor = '${editor_cmd}'
lang = 'python3'
edit_code_marker = true
comment_problem_desc = true
inject_before = ["from typing import List, Optional, Dict, Set, Tuple"]
inject_after = []
test = true

[cookies]
csrf = ''
session = ''
site = 'leetcode.com'

[storage]
cache = 'Problems'
code = 'code'
root = '~/.leetcode'
scripts = 'scripts'
LEETCODECONFIG

    ok "leetcode-cli config written to $LC_DIR/leetcode.toml"
    info "Set your preferred language in ~/.leetcode/leetcode.toml [code] lang"
    info "Set your cookies by running: leetcode data -c"
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

write_mcp_claude() {
    local path="$1"
    [ -f "$path" ] && { warn "Backing up Claude Desktop config"; cp "$path" "$path.bak"; }
    export LEET_MCP_CONFIG_PATH="$path"
    python3 << 'PY'
import json, os
path = os.environ['LEET_MCP_CONFIG_PATH']
pkg = f"{os.environ['LEET_MCP_PACKAGE']}@{os.environ['LEET_MCP_VERSION']}"
site = os.environ['LEET_MCP_SITE']
cfg = {}
if os.path.exists(path):
    with open(path) as f:
        cfg = json.load(f)
servers = cfg.setdefault('mcpServers', {})
servers['leetcode'] = {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", pkg, "--site", site],
    "env": {"LEETCODE_SITE": site, "LEETCODE_SESSION": ""},
}
with open(path, 'w') as f:
    json.dump(cfg, f, indent=2)
PY
    ok "Claude Desktop MCP config written (leetcode server merged)"
}

write_mcp_codex() {
    local path="$1"
    if [ -f "$path" ] && grep -q "mcp_servers.leetcode" "$path" 2>/dev/null; then
        info "Codex leetcode MCP already configured, skipping"
        return 0
    fi
    cat >> "$path" << CODEXMCP

# leet-teach: leetcode MCP server
[mcp_servers.leetcode]
command = "npx"
args = ["-y", "${MCP_SERVER_PACKAGE}@${MCP_SERVER_VERSION}", "--site", "${MCP_SITE}"]

[mcp_servers.leetcode.env]
LEETCODE_SITE = "${MCP_SITE}"
LEETCODE_SESSION = ""
CODEXMCP
    ok "Codex MCP config added to $path"
}

write_mcp_opencode() {
    local path="$1"
    [ -f "$path" ] && { warn "Backing up OpenCode config"; cp "$path" "$path.bak"; }
    export LEET_MCP_CONFIG_PATH="$path"
    python3 << 'PY'
import json, os
path = os.environ['LEET_MCP_CONFIG_PATH']
pkg = f"{os.environ['LEET_MCP_PACKAGE']}@{os.environ['LEET_MCP_VERSION']}"
site = os.environ['LEET_MCP_SITE']
cfg = {}
if os.path.exists(path):
    with open(path) as f:
        cfg = json.load(f)
mcp = cfg.setdefault('mcp', {})
mcp['leetcode'] = {
    "type": "local",
    "enabled": True,
    "command": ["npx", "-y", pkg, "--site", site],
    "environment": {"LEETCODE_SITE": site, "LEETCODE_SESSION": ""},
}
with open(path, 'w') as f:
    json.dump(cfg, f, indent=2)
PY
    ok "OpenCode MCP config written (leetcode server merged)"
}

write_mcp_templates() {
    info "Refreshing MCP config templates in $PROJ_DIR/mcp-configs/"
    local pkg="${MCP_SERVER_PACKAGE}@${MCP_SERVER_VERSION}"
    cat > "$PROJ_DIR/mcp-configs/claude-desktop.json" << EOF
{
  "mcpServers": {
    "leetcode": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "${pkg}", "--site", "${MCP_SITE}"],
      "env": {
        "LEETCODE_SITE": "${MCP_SITE}",
        "LEETCODE_SESSION": ""
      }
    }
  }
}
EOF
    cat > "$PROJ_DIR/mcp-configs/codex.toml" << EOF
# Add to ~/.codex/config.toml
# Codex uses TOML for MCP config, not JSON

[mcp_servers.leetcode]
command = "npx"
args = ["-y", "${pkg}", "--site", "${MCP_SITE}"]

[mcp_servers.leetcode.env]
LEETCODE_SITE = "${MCP_SITE}"
LEETCODE_SESSION = ""
EOF
    cat > "$PROJ_DIR/mcp-configs/opencode.json" << EOF
{
  "mcp": {
    "leetcode": {
      "type": "local",
      "enabled": true,
      "command": ["npx", "-y", "${pkg}", "--site", "${MCP_SITE}"],
      "environment": {
        "LEETCODE_SITE": "${MCP_SITE}",
        "LEETCODE_SESSION": ""
      }
    }
  }
}
EOF
    ok "MCP config templates refreshed"
}

configure_mcp() {
    info "Configuring MCP for Claude, Codex, and OpenCode..."
    command -v python3 >/dev/null || die "python3 required to merge MCP configs"
    export LEET_MCP_PACKAGE="$MCP_SERVER_PACKAGE" LEET_MCP_VERSION="$MCP_SERVER_VERSION" LEET_MCP_SITE="$MCP_SITE"

    mkdir -p "$HOME/.config/claude" "$HOME/.codex" "$HOME/.config/opencode"
    write_mcp_claude   "$HOME/.config/claude/claude_desktop_config.json"
    write_mcp_codex    "$HOME/.codex/config.toml"
    write_mcp_opencode "$HOME/.config/opencode/config.json"
    write_mcp_templates

    info ""
    warn "IMPORTANT: Set your LEETCODE_SESSION cookie in the config files!"
    info "  1. Log in to https://leetcode.com in your browser"
    info "  2. Open DevTools (F12) → Application → Cookies"
    info "  3. Copy the LEETCODE_SESSION value"
    info "  4. Set it in the MCP configs, or run: leetcode data -c"
}

install_skill() {
    local repo="$1" name="$2"
    info "Installing $name skill from $repo..."
    npx "skills@${SKILLS_VERSION}" add "$repo" --skill "$name" -y \
        || die "failed to install $name skill from $repo"
}

install_skills() {
    info "Installing skills (mattpocock/teach + local leetcode skill)..."
    cd "$PROJ_DIR"
    command -v npx >/dev/null || die "npx not found. Install Node.js first: https://nodejs.org/"
    install_skill mattpocock/skills teach
    install_skill madebymlai/leet-teach leetcode
    ok "Skills setup complete"
}

setup_project() {
    info "Setting up project workspace..."
    mkdir -p "$PROJ_DIR"/{lessons,learning-records,reference}
    ok "Project directories created"
}

main() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════╗"
    echo "║       leet-teach setup                   ║"
    echo "║  helix + leetcode-cli + MCP + skills     ║"
    echo "╚══════════════════════════════════════════╝"
    echo -e "${NC}"

    local steps=("helix" "helix-config" "tmux-config" "leetcode-cli" "leetcode-config" "mcp-install" "mcp-config" "skills" "project")
    local failed=()

    for step in "${steps[@]}"; do
        echo ""
        info "=== Step: $step ==="
        case "$step" in
            helix)           install_helix || failed+=("$step") ;;
            helix-config)    configure_helix || failed+=("$step") ;;
            tmux-config)     configure_tmux || failed+=("$step") ;;
            leetcode-cli)    install_leetcode_cli || failed+=("$step") ;;
            leetcode-config) configure_leetcode_cli || failed+=("$step") ;;
            mcp-install)     install_mcp_server || failed+=("$step") ;;
            mcp-config)      configure_mcp || failed+=("$step") ;;
            skills)          install_skills || failed+=("$step") ;;
            project)         setup_project || failed+=("$step") ;;
        esac
    done

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
    echo "  1. Set your LeetCode cookies:  leetcode data -c"
    echo "  2. Edit MCP session cookie in:"
    echo "     ~/.config/claude/claude_desktop_config.json"
    echo "     ~/.codex/config.toml"
    echo "     ~/.config/opencode/config.json"
    echo "  3. Pick a problem:             leet pick two-sum"
    echo "  4. Edit in helix:              leet edit 1"
    echo "  5. Test:                       leet test 1"
    echo "  6. Submit:                     leet submit 1"
    echo ""
    echo -e "${YELLOW}Or let your AI coach handle it via MCP tools.${NC}"
}

main "$@"
