#!/bin/bash
# functions.sh - All function declarations (no executable statements)
# Sourced via params.sh

[ -n "$JIRA_FUNCTIONS_LOADED" ] && return 0
JIRA_FUNCTIONS_LOADED=1

# ============================================================
# Output helpers
# ============================================================
info()  { echo "[INFO]  $*"; }
warn()  { echo "[WARN]  $*" >&2; }
error() { echo "[ERROR] $*" >&2; }
ok()    { echo "[OK]    $*"; }

# ============================================================
# CLI detection
# ============================================================
detect_cli() {
    local parent
    parent=$(ps -o comm= -p $PPID 2>/dev/null)
    case "$parent" in
        *claude*) echo "claude"; return ;;
        *codex*)  echo "codex";  return ;;
        *gemini*) echo "gemini"; return ;;
    esac

    if command -v claude &>/dev/null; then echo "claude"; return; fi
    if command -v codex &>/dev/null;  then echo "codex";  return; fi
    if command -v gemini &>/dev/null; then echo "gemini"; return; fi

    echo ""
}

get_cli_config() {
    local cli="$1"
    case "$cli" in
        claude)
            CLI_HOME="$HOME/.claude"
            CLI_COMMANDS_DIR="$CLI_HOME/commands"
            CLI_GLOBAL_MCP="$CLI_HOME/settings.json"
            CLI_PROJECT_MCP="$JIRA_ROOT/.claude/settings.local.json"
            CLI_MCP_FORMAT="json"
            CLI_MCP_KEY="mcpServers"
            CLI_PROMPT_FLAG="-p"
            CLI_TOOLS_FLAGS=(--allowedTools "Bash" "Read" "Write" "Edit" "Glob" "Grep"
                "mcp__claude_ai_Atlassian__*"
                "mcp__claude_ai_Atlassian_Rovo__*"
                "mcp__mcp-atlassian__*"
            )
            ;;
        codex)
            CLI_HOME="$HOME/.codex"
            CLI_COMMANDS_DIR="$CLI_HOME/commands"
            CLI_GLOBAL_MCP="$CLI_HOME/config.toml"
            CLI_PROJECT_MCP="$JIRA_ROOT/.codex/config.toml"
            CLI_MCP_FORMAT="toml"
            CLI_MCP_KEY="mcp_servers"
            CLI_PROMPT_FLAG="-q"
            CLI_TOOLS_FLAGS=()
            ;;
        gemini)
            CLI_HOME="$HOME/.gemini"
            CLI_COMMANDS_DIR="$CLI_HOME/commands"
            CLI_GLOBAL_MCP="$CLI_HOME/settings.json"
            CLI_PROJECT_MCP="$JIRA_ROOT/.gemini/settings.json"
            CLI_MCP_FORMAT="json"
            CLI_MCP_KEY="mcpServers"
            CLI_PROMPT_FLAG="-p"
            CLI_TOOLS_FLAGS=()
            ;;
        *)
            CLI_HOME=""
            CLI_COMMANDS_DIR=""
            CLI_GLOBAL_MCP=""
            CLI_PROJECT_MCP=""
            CLI_MCP_FORMAT=""
            CLI_MCP_KEY=""
            CLI_PROMPT_FLAG=""
            CLI_TOOLS_FLAGS=()
            ;;
    esac
}

# ============================================================
# Jira config validation
# ============================================================
require_jira_config() {
    local missing=0
    if [ -z "$JIRA_CLOUD_URL" ]; then
        error "JIRA_CLOUD_URL is not set"
        missing=1
    fi
    if [ -z "$JIRA_CLOUD_ID" ]; then
        error "JIRA_CLOUD_ID is not set"
        missing=1
    fi
    if [ "$missing" = "1" ]; then
        echo "" >&2
        echo "  Set environment variables before running:" >&2
        echo "    export JIRA_CLOUD_URL=\"https://your-site.atlassian.net\"" >&2
        echo "    export JIRA_CLOUD_ID=\"your-site.atlassian.net\"" >&2
        echo "" >&2
        echo "  Or add them to your shell profile (~/.bashrc, ~/.zshrc)" >&2
        return 1
    fi
    ok "Jira: $JIRA_CLOUD_ID"
}

# ============================================================
# CLI validation
# ============================================================
require_cli() {
    if [ -z "$CLI_NAME" ]; then
        error "No supported CLI detected (claude/codex/gemini)"
        error "Install one or set JIRA_CLI_OVERRIDE=<cli-name>"
        return 1
    fi
    if [ -z "$CLI_BIN" ]; then
        error "$CLI_NAME is detected but binary not found in PATH"
        return 1
    fi
    ok "CLI: $CLI_NAME ($CLI_BIN)"
}

# ============================================================
# MCP / Jira access
# ============================================================
check_jira_builtin_access() {
    # Check both global and project-local for existing MCP config
    for f in "$CLI_GLOBAL_MCP" "$CLI_PROJECT_MCP"; do
        if [ -f "$f" ] && grep -q "mcp-atlassian\|mcp_atlassian" "$f" 2>/dev/null; then
            echo "local"
            return 0
        fi
    done
    echo "unknown"
    return 1
}

setup_mcp_atlassian() {
    local url="$1"
    local token="$2"
    local mcp_file="$CLI_PROJECT_MCP"

    if [ -z "$mcp_file" ]; then
        error "CLI not detected, cannot configure MCP"
        return 1
    fi

    mkdir -p "$(dirname "$mcp_file")"

    case "$CLI_MCP_FORMAT" in
        json)
            _setup_mcp_json "$mcp_file" "$url" "$token"
            ;;
        toml)
            _setup_mcp_toml "$mcp_file" "$url" "$token"
            ;;
        *)
            error "Unknown MCP config format: $CLI_MCP_FORMAT"
            return 1
            ;;
    esac

    ok "MCP config written to $mcp_file (project-local, $CLI_NAME)"
}

_setup_mcp_json() {
    local mcp_file="$1" url="$2" token="$3"

    if [ -f "$mcp_file" ]; then
        python3 -c "
import json
with open('$mcp_file', 'r') as f:
    data = json.load(f)
servers = data.setdefault('$CLI_MCP_KEY', {})
servers['mcp-atlassian'] = {
    'command': 'uvx',
    'args': ['mcp-atlassian'],
    'env': {
        'JIRA_URL': '$url',
        'JIRA_AUTH_TYPE': 'token',
        'JIRA_TOKEN': '$token'
    }
}
with open('$mcp_file', 'w') as f:
    json.dump(data, f, indent=2)
"
    else
        cat > "$mcp_file" <<MCPEOF
{
  "$CLI_MCP_KEY": {
    "mcp-atlassian": {
      "command": "uvx",
      "args": ["mcp-atlassian"],
      "env": {
        "JIRA_URL": "$url",
        "JIRA_AUTH_TYPE": "token",
        "JIRA_TOKEN": "$token"
      }
    }
  }
}
MCPEOF
    fi
}

_setup_mcp_toml() {
    local mcp_file="$1" url="$2" token="$3"

    # Append or create TOML config for Codex
    if [ -f "$mcp_file" ] && grep -q "mcp_servers.mcp-atlassian" "$mcp_file" 2>/dev/null; then
        info "mcp-atlassian already in $mcp_file, skipping"
        return 0
    fi

    cat >> "$mcp_file" <<TOMLEOF

[mcp_servers.mcp-atlassian]
command = "uvx"
args = ["mcp-atlassian"]

[mcp_servers.mcp-atlassian.env]
JIRA_URL = "$url"
JIRA_AUTH_TYPE = "token"
JIRA_TOKEN = "$token"
TOMLEOF
}

# ============================================================
# Symlink helpers
# ============================================================
install_symlink() {
    local source="$1"
    local target="$2"

    if [ ! -f "$source" ]; then
        error "Source not found: $source"
        return 1
    fi

    mkdir -p "$(dirname "$target")"

    if [ -e "$target" ] || [ -L "$target" ]; then
        rm "$target"
    fi

    ln -s "$source" "$target"
    ok "Linked: $target -> $source"
}

remove_symlink() {
    local target="$1"

    if [ -e "$target" ] || [ -L "$target" ]; then
        rm "$target"
        ok "Removed: $target"
    else
        info "Not found (already removed): $target"
    fi
}

# ============================================================
# Cron helpers
# ============================================================
install_cron() {
    local cron_expr="$1"
    local command="$2"
    local tag="$3"

    local existing
    existing=$(crontab -l 2>/dev/null | grep -v "$tag" || true)

    local cron_line="$cron_expr $command $tag"

    if [ -n "$existing" ]; then
        printf '%s\n%s\n' "$existing" "$cron_line" | crontab -
    else
        echo "$cron_line" | crontab -
    fi

    ok "Cron installed: $cron_expr ($tag)"
}

remove_cron() {
    local tag="$1"
    local existing
    existing=$(crontab -l 2>/dev/null | grep -v "$tag" || true)

    if [ -n "$existing" ]; then
        echo "$existing" | crontab -
    else
        crontab -r 2>/dev/null || true
    fi

    ok "Cron removed: $tag"
}

# ============================================================
# Skill management
# ============================================================
install_skill() {
    local skill_name="$1"
    local source_file="$JIRA_SKILLS_DIR/$skill_name/$skill_name.md"
    local target_file="$CLI_COMMANDS_DIR/$skill_name.md"

    require_cli || return 1
    require_jira_config || return 1
    install_symlink "$source_file" "$target_file"
    info "Usage: Type /$skill_name in $CLI_NAME session"
}

uninstall_skill() {
    local skill_name="$1"
    local target_file="$CLI_COMMANDS_DIR/$skill_name.md"

    remove_symlink "$target_file"
}

# ============================================================
# Schedule management
# ============================================================
install_schedule() {
    local skill_name="$1"
    local cron_expr="${2:-0 7 * * 1}"
    local skill_schedule_dir="$JIRA_SKILLS_DIR/$skill_name/schedule"
    local run_script="$skill_schedule_dir/run.sh"
    local cron_tag="# ${skill_name}-scheduled"

    require_cli || return 1
    require_jira_config || return 1
    chmod +x "$run_script"
    install_cron "$cron_expr" "$run_script" "$cron_tag"

    info "Run manually:  $run_script"
    info "View logs:     ls $skill_schedule_dir/logs/"
    info "Remove:        Use --remove"
}

uninstall_schedule() {
    local skill_name="$1"
    local cron_tag="# ${skill_name}-scheduled"

    remove_cron "$cron_tag"
}

# ============================================================
# Skill runner
# ============================================================
run_skill() {
    local skill_name="$1"
    local rules_dir="$JIRA_SKILLS_DIR/$skill_name/rules"
    local log_dir="$JIRA_SKILLS_DIR/$skill_name/schedule/logs"
    local timestamp=$(date +%Y-%m-%d_%H%M%S)
    local log_file="$log_dir/${timestamp}.log"

    require_cli || return 1
    require_jira_config || return 1
    mkdir -p "$log_dir"

    echo "=== $skill_name started at $(date '+%Y-%m-%d %H:%M:%S %Z') ===" | tee "$log_file"
    echo "=== CLI: $CLI_NAME ($CLI_BIN) ===" | tee -a "$log_file"

    if [ -d "$rules_dir" ]; then
        # 6-pass: run each rule file separately
        for rule_file in "$rules_dir"/rule*.md; do
            [ ! -f "$rule_file" ] && continue
            local rule_name=$(basename "$rule_file" .md)
            local rule_prompt
            rule_prompt=$(render_template "$rule_file")

            echo "" | tee -a "$log_file"
            echo "--- $rule_name started at $(date '+%H:%M:%S') ---" | tee -a "$log_file"

            $CLI_BIN $CLI_PROMPT_FLAG "$rule_prompt" \
                "${CLI_TOOLS_FLAGS[@]}" \
                --max-turns 50 \
                2>&1 | tee -a "$log_file"

            echo "--- $rule_name finished at $(date '+%H:%M:%S') ---" | tee -a "$log_file"
        done
    else
        # fallback: single-pass with main skill file
        local skill_file="$JIRA_SKILLS_DIR/$skill_name/$skill_name.md"
        if [ ! -f "$skill_file" ]; then
            error "No rules dir or skill file found for $skill_name"
            return 1
        fi

        $CLI_BIN $CLI_PROMPT_FLAG "$(render_template "$skill_file") Execute all rules now." \
            "${CLI_TOOLS_FLAGS[@]}" \
            --max-turns 50 \
            2>&1 | tee -a "$log_file"
    fi

    echo "" | tee -a "$log_file"
    echo "=== $skill_name finished at $(date '+%Y-%m-%d %H:%M:%S %Z') ===" | tee -a "$log_file"

    # Keep only last 30 logs
    ls -t "$log_dir"/*.log 2>/dev/null | tail -n +31 | xargs rm -f 2>/dev/null || true
}

# ============================================================
# Environment setup (interactive)
# ============================================================
setup_environment() {
    echo "========================================="
    echo "  Jira Workspace Environment Setup"
    echo "========================================="
    echo ""

    info "Detecting CLI..."
    require_cli || return 1
    echo ""

    # Jira access
    info "Checking Jira access..."
    local access_type skip_mcp
    access_type=$(check_jira_builtin_access)

    if [ "$access_type" = "local" ]; then
        ok "Local MCP (mcp-atlassian) already configured"
        skip_mcp=1
    else
        echo ""
        echo "  Jira access can be configured in two ways:"
        echo "  1) Built-in connector (claude.ai/settings/connectors)"
        echo "  2) Local MCP server (API token required)"
        echo ""
        read -p "  Is built-in Atlassian connector already connected? [y/N]: " builtin_ok

        if [[ "$builtin_ok" =~ ^[yY] ]]; then
            ok "Using built-in connector, skipping MCP setup"
            skip_mcp=1
        else
            skip_mcp=0
        fi
    fi

    if [ "$skip_mcp" = "0" ]; then
        echo ""
        info "Setting up local MCP (mcp-atlassian)..."
        echo ""
        read -p "  Jira URL [${JIRA_CLOUD_URL}]: " input_url
        local jira_url="${input_url:-$JIRA_CLOUD_URL}"
        read -sp "  Jira API Token: " input_token
        echo ""

        if [ -z "$input_token" ]; then
            error "Token is required"
            return 1
        fi
        setup_mcp_atlassian "$jira_url" "$input_token"
    fi

    echo ""

    # Skills
    info "Installing skills..."
    install_skill "jira-update"
    echo ""

    # Schedule
    info "Installing schedule..."
    read -p "  Install weekly cron (Monday 7am)? [Y/n]: " install_cron_yn

    if [[ ! "$install_cron_yn" =~ ^[nN] ]]; then
        read -p "  Cron expression [0 7 * * 1]: " custom_cron
        install_schedule "jira-update" "${custom_cron:-0 7 * * 1}"
    else
        info "Skipped cron setup"
    fi

    echo ""
    echo "========================================="
    echo "  Setup Complete!"
    echo "========================================="
    echo ""
    echo "  CLI:       $CLI_NAME"
    echo "  Skills:    /jira-update"
    echo "  Skill MD:  $JIRA_SKILLS_DIR/jira-update/jira-update.md"
    echo "  Manual:    $JIRA_SKILLS_DIR/jira-update/schedule/run.sh"
    echo "  Logs:      $JIRA_SKILLS_DIR/jira-update/schedule/logs/"
    echo ""
}

teardown_environment() {
    info "Removing jira workspace setup..."
    uninstall_skill "jira-update" 2>/dev/null || true
    uninstall_schedule "jira-update" 2>/dev/null || true
    ok "All removed."
}

# ============================================================
# Template helpers
# ============================================================
render_template() {
    local file="$1"
    sed \
        -e "s|{{JIRA_CLOUD_ID}}|${JIRA_CLOUD_ID}|g" \
        -e "s|{{JIRA_CLOUD_URL}}|${JIRA_CLOUD_URL}|g" \
        "$file"
}

# ============================================================
# Date helpers
# ============================================================
next_friday() {
    python3 -c "
from datetime import date, timedelta
today = date.today()
days_ahead = 4 - today.weekday()
if days_ahead <= 0:
    days_ahead += 7
print((today + timedelta(days=days_ahead)).isoformat())
"
}

subtract_business_days() {
    local date_str="$1"
    local days="$2"
    python3 -c "
from datetime import datetime, timedelta
dt = datetime.strptime('$date_str', '%Y-%m-%d')
days = $days
while days > 0:
    dt -= timedelta(days=1)
    if dt.weekday() < 5:
        days -= 1
print(dt.strftime('%Y-%m-%d'))
"
}
