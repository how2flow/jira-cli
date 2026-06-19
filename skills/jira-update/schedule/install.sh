#!/bin/bash
set -e
source "$(cd "$(dirname "$0")"; while [ ! -f .jira-root ]; do cd ..; done; pwd)/scripts/params.sh"

if [ "$1" = "--remove" ]; then
    uninstall_schedule "jira-update"
else
    install_schedule "jira-update" "${1:-0 7 * * 1}"
fi
