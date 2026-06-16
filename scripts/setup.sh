#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

PROJ_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*"; }

check_cmd() {
    if command -v "$1" &>/dev/null; then
        ok "$1 found: $(command -v "$1")"
        return 0
    else
        warn "$1 not found"
        return 1
    fi
}

install_helix() {
    info "Checking for helix editor..."
    if command -v hx &>/dev/null; then
        ok "helix already installed: $(command -v hx)"
        return 0
    elif command -v helix &>/dev/null; then
        ok "helix already installed: $(command -v helix)"
        # Symlink hx -> helix if not already present
        if [ ! -e /usr/local/bin/hx ] && [ ! -e "$HOME/.local/bin/hx" ]; then
            info "Creating hx symlink -> helix..."
            mkdir -p "$HOME/.local/bin"
            ln -sf "$(command -v helix)" "$HOME/.local/bin/hx"
            ok "Created $HOME/.local/bin/hx -> $(command -v helix)"
            export PATH="$HOME/.local/bin:$PATH"
        fi
        return 0
    fi

    err "helix (hx/helix) not found."
    echo ""
    echo -e "${YELLOW}Please install helix before running this script.${NC}"
    echo -e "${YELLOW}Installation guide: https://docs.helix-editor.com/install.html${NC}"
    echo ""
    echo "Quick install options:"
    echo "  brew install helix"
    echo "  cargo install helix-term"
    echo "  sudo pacman -S helix"
    echo "  sudo dnf install helix"
    echo "  Or download from: https://github.com/helix-editor/helix/releases"
    echo ""
    read -rp "Press Enter to exit, or type 'retry' after installing helix: " choice
    if [ "$choice" = "retry" ]; then
        if check_cmd hx; then
            ok "helix found: $(command -v hx)"
            return 0
        else
            err "helix still not found. Exiting."
            exit 1
        fi
    else
        exit 1
    fi
}

configure_helix() {
    info "Configuring helix for LeetCode..."
    HELIX_CONFIG_DIR="$HOME/.config/helix"
    mkdir -p "$HELIX_CONFIG_DIR"

    if [ -f "$HELIX_CONFIG_DIR/config.toml" ]; then
        warn "helix config already exists at $HELIX_CONFIG_DIR/config.toml"
        warn "Backing up to config.toml.bak"
        cp "$HELIX_CONFIG_DIR/config.toml" "$HELIX_CONFIG_DIR/config.toml.bak"
    fi

    cat > "$HELIX_CONFIG_DIR/config.toml" << 'HELIXCONFIG'
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

    mkdir -p "$HELIX_CONFIG_DIR"
    if [ ! -f "$HELIX_CONFIG_DIR/languages.toml" ] || ! grep -q "leetcode" "$HELIX_CONFIG_DIR/languages.toml" 2>/dev/null; then
        cat > "$HELIX_CONFIG_DIR/languages.toml" << 'LANGSCONFIG'
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
    fi
}

configure_tmux() {
    info "Configuring tmux..."
    TMUX_CONFIG="$HOME/.tmux.conf"
    touch "$TMUX_CONFIG"

    # Mouse support
    if ! grep -q "set -g mouse on" "$TMUX_CONFIG" 2>/dev/null; then
        echo "" >> "$TMUX_CONFIG"
        echo "# leet-teach: enable mouse" >> "$TMUX_CONFIG"
        echo "set -g mouse on" >> "$TMUX_CONFIG"
        ok "tmux mouse enabled"
    else
        info "tmux mouse already enabled"
    fi

    # Alt+arrow to switch panes (alongside Ctrl+B arrows)
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

    # Reload tmux if running
    if [ -n "${TMUX:-}" ]; then
        tmux source-file "$TMUX_CONFIG" 2>/dev/null && ok "tmux config reloaded" || warn "Could not reload tmux config (will apply on next session)"
    fi
}

install_leetcode_cli() {
    info "Installing leetcode-cli (clearloop)..."
    if check_cmd leetcode; then
        info "leetcode-cli already installed, skipping"
        return 0
    fi

    if check_cmd cargo; then
        cargo install leetcode-cli
    else
        warn "cargo not found. Installing rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
        cargo install leetcode-cli
    fi

    if check_cmd leetcode; then
        ok "leetcode-cli installed successfully"
    else
        err "Failed to install leetcode-cli. Install manually: cargo install leetcode-cli"
        return 1
    fi
}

configure_leetcode_cli() {
    info "Configuring leetcode-cli..."
    LC_DIR="$HOME/.leetcode"
    mkdir -p "$LC_DIR"

    if [ -f "$LC_DIR/leetcode.toml" ]; then
        warn "leetcode.toml already exists, backing up"
        cp "$LC_DIR/leetcode.toml" "$LC_DIR/leetcode.toml.bak"
    fi

    local editor_cmd="hx"
    if command -v hx &>/dev/null; then
        editor_cmd="hx"
    elif command -v helix &>/dev/null; then
        editor_cmd="helix"
    elif [ -n "${EDITOR:-}" ]; then
        editor_cmd="$EDITOR"
    fi

    cat > "$LC_DIR/leetcode.toml" << LEETCODECONFIG
[code]
editor = '${editor_cmd}'
lang = 'python3'
edit_code_marker = true
comment_problem_desc = true
comment_leading = "#"
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
    else
        warn "npx not found. Installing Node.js..."
        if check_cmd brew; then
            brew install node
        elif check_cmd apt-get; then
            curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
            sudo apt-get install -y nodejs
        elif check_cmd pacman; then
            sudo pacman -S --noconfirm nodejs npm
        fi
    fi

    ok "MCP server ready (runs via: npx -y @jinzcdev/leetcode-mcp-server)"
}

configure_mcp() {
    info "Configuring MCP for Claude, Codex, and OpenCode..."

    local mcp_cmd="npx"
    local mcp_args='-y @jinzcdev/leetcode-mcp-server --site global'

    # --- Claude Desktop ---
    CLAUDE_CONFIG_DIR="$HOME/.config/claude"
    mkdir -p "$CLAUDE_CONFIG_DIR"
    if [ -f "$CLAUDE_CONFIG_DIR/claude_desktop_config.json" ]; then
        warn "Claude Desktop config exists, backing up"
        cp "$CLAUDE_CONFIG_DIR/claude_desktop_config.json" "$CLAUDE_CONFIG_DIR/claude_desktop_config.json.bak"
    fi

    cat > "$CLAUDE_CONFIG_DIR/claude_desktop_config.json" << CLAUDEMCP
{
  "mcpServers": {
    "leetcode": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@jinzcdev/leetcode-mcp-server", "--site", "global"],
      "env": {
        "LEETCODE_SITE": "global",
        "LEETCODE_SESSION": ""
      }
    }
  }
}
CLAUDEMCP
    ok "Claude Desktop MCP config written"

    # --- Claude Code / Codex ---
    CODEX_CONFIG_DIR="$HOME/.codex"
    mkdir -p "$CODEX_CONFIG_DIR"
    cat > "$CODEX_CONFIG_DIR/mcp.json" << CODEXMCP
{
  "mcpServers": {
    "leetcode": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@jinzcdev/leetcode-mcp-server", "--site", "global"],
      "env": {
        "LEETCODE_SITE": "global",
        "LEETCODE_SESSION": ""
      }
    }
  }
}
CODEXMCP
    ok "Codex MCP config written"

    # --- OpenCode ---
    OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
    mkdir -p "$OPENCODE_CONFIG_DIR"
    if [ -f "$OPENCODE_CONFIG_DIR/config.json" ]; then
        warn "OpenCode config exists, backing up"
        cp "$OPENCODE_CONFIG_DIR/config.json" "$OPENCODE_CONFIG_DIR/config.json.bak"
    fi

    python3 -c "
import json, os
cfg = {}
path = '$OPENCODE_CONFIG_DIR/config.json'
if os.path.exists(path):
    with open(path) as f:
        cfg = json.load(f)
mcp = cfg.get('mcp', {})
mcp['leetcode'] = {
    'type': 'local',
    'enabled': True,
    'command': ['npx', '-y', '@jinzcdev/leetcode-mcp-server', '--site', 'global'],
    'environment': {
        'LEETCODE_SITE': 'global',
        'LEETCODE_SESSION': ''
    }
}
cfg['mcp'] = mcp
with open(path, 'w') as f:
    json.dump(cfg, f, indent=2)
" 2>/dev/null || warn "Could not update OpenCode config automatically — see mcp-configs/opencode.json for manual setup"

    ok "OpenCode MCP config written"

    # Also copy template configs to project
    cp "$PROJ_DIR/mcp-configs/claude-desktop.json" "$PROJ_DIR/mcp-configs/claude-desktop.json.bak" 2>/dev/null || true
    info "MCP config templates saved to $PROJ_DIR/mcp-configs/"
    info ""
    warn "IMPORTANT: Set your LEETCODE_SESSION cookie in the config files!"
    info "  1. Log in to https://leetcode.com in Firefox"
    info "  2. Open DevTools (F12) → Storage → Cookies"
    info "  3. Copy the LEETCODE_SESSION value"
    info "  4. Set it in: ~/.config/claude/claude_desktop_config.json"
    info "     or run: leetcode data -c"
}

install_skills() {
    info "Installing skills (mattpocock/teach + local leetcode skill)..."

    cd "$PROJ_DIR"

    if ! check_cmd npx; then
        err "npx not found. Cannot install skills. Install Node.js first: https://nodejs.org/"
        return 1
    fi

    # Install mattpocock teach skill (project-local, not -g)
    info "Installing mattpocock/skills teach skill (project-local)..."
    npx skills@latest add mattpocock/skills --skill teach -y 2>/dev/null || {
        warn "npx skills add failed, trying manual setup..."
        mkdir -p "$PROJ_DIR/.skills/teach"
        curl -fsSL "https://raw.githubusercontent.com/mattpocock/skills/main/skills/productivity/teach/SKILL.md" \
            -o "$PROJ_DIR/.skills/teach/SKILL.md"
        curl -fsSL "https://raw.githubusercontent.com/mattpocock/skills/main/skills/productivity/teach/MISSION-FORMAT.md" \
            -o "$PROJ_DIR/.skills/teach/MISSION-FORMAT.md"
        curl -fsSL "https://raw.githubusercontent.com/mattpocock/skills/main/skills/productivity/teach/LEARNING-RECORD-FORMAT.md" \
            -o "$PROJ_DIR/.skills/teach/LEARNING-RECORD-FORMAT.md"
        curl -fsSL "https://raw.githubusercontent.com/mattpocock/skills/main/skills/productivity/teach/RESOURCES-FORMAT.md" \
            -o "$PROJ_DIR/.skills/teach/RESOURCES-FORMAT.md"
        curl -fsSL "https://raw.githubusercontent.com/mattpocock/skills/main/skills/productivity/teach/GLOSSARY-FORMAT.md" \
            -o "$PROJ_DIR/.skills/teach/GLOSSARY-FORMAT.md"
        ok "teach skill files downloaded manually to .skills/teach/"
    }

    # Install the leetcode skill from GitHub
    info "Installing leetcode skill from GitHub..."
    npx skills@latest add madebymlai/leet-teach --skill leetcode -y 2>/dev/null || {
        warn "Could not install leetcode skill from GitHub."
        warn "The skill is available at skills/leetcode/SKILL.md"
        warn "Install manually: npx skills@latest add madebymlai/leet-teach --skill leetcode"
    }

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
            helix)         install_helix || failed+=("$step") ;;
            helix-config)  configure_helix || failed+=("$step") ;;
            tmux-config)   configure_tmux || failed+=("$step") ;;
            leetcode-cli)  install_leetcode_cli || failed+=("$step") ;;
            leetcode-config) configure_leetcode_cli || failed+=("$step") ;;
            mcp-install)   install_mcp_server || failed+=("$step") ;;
            mcp-config)    configure_mcp || failed+=("$step") ;;
            skills)        install_skills || failed+=("$step") ;;
            project)       setup_project || failed+=("$step") ;;
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
    echo "     ~/.codex/mcp.json"
    echo "     ~/.config/opencode/config.json"
    echo "  3. Pick a problem:             leetcode pick two-sum"
    echo "  4. Edit in helix:              leetcode edit 1"
    echo "  5. Test:                       leetcode test 1"
    echo "  6. Submit:                      leetcode exec 1"
    echo ""
    echo -e "${YELLOW}Or let your AI coach handle it via MCP tools.${NC}"
}

main "$@"