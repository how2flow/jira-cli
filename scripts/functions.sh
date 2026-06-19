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
