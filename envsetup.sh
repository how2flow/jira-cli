#!/bin/bash
set -e
source "$(cd "$(dirname "$0")"; while [ ! -f .jira-root ]; do cd ..; done; pwd)/scripts/params.sh"
