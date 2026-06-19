#!/bin/bash
set -e
source "$(cd "$(dirname "$0")"; while [ ! -f .jira-root ]; do cd ..; done; pwd)/scripts/params.sh"

if [ "$1" = "--remove" ]; then
    uninstall_skill "jira-update"
else
    install_skill "jira-update"
fi
