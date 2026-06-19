#!/bin/bash
# params.sh - Variable initialization only
# Sources functions.sh, then calls functions to populate variables
# All scripts source this file: source "$(dirname "$0")/../scripts/params.sh"

[ -n "$JIRA_PARAMS_LOADED" ] && return 0
JIRA_PARAMS_LOADED=1

# Paths
JIRA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"; while [ ! -f .jira-root ]; do cd ..; done; pwd)"
JIRA_SCRIPTS_DIR="$JIRA_ROOT/scripts"
JIRA_SKILLS_DIR="$JIRA_ROOT/skills"

# Load functions
source "$JIRA_SCRIPTS_DIR/functions.sh"

# Detect CLI and set CLI_* variables
CLI_NAME="${JIRA_CLI_OVERRIDE:-$(detect_cli)}"
CLI_BIN=$(command -v "$CLI_NAME" 2>/dev/null || echo "")
get_cli_config "$CLI_NAME"

# Jira defaults
JIRA_CLOUD_URL="${JIRA_CLOUD_URL:-}"
JIRA_CLOUD_ID="${JIRA_CLOUD_ID:-}"

# Debug
if [ "${JIRA_DEBUG:-0}" = "1" ]; then
    echo "[params] CLI_NAME=$CLI_NAME"
    echo "[params] CLI_BIN=$CLI_BIN"
    echo "[params] CLI_HOME=$CLI_HOME"
    echo "[params] CLI_COMMANDS_DIR=$CLI_COMMANDS_DIR"
    echo "[params] JIRA_ROOT=$JIRA_ROOT"
fi
