#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/install.log"

GREEN='\033[1;32m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[+]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >> "$LOG_FILE"
}

done_file() {
    echo "$SCRIPT_DIR/.done_$1"
}

is_done() {
    [ -f "$(done_file "$1")" ]
}

mark_done() {
    touch "$(done_file "$1")"
}

run_step() {
    local name="$1"
    shift

    if is_done "$name"; then
        log "$name already done ✅"
        return
    fi

    log "Running $name..."
    "$@"
    mark_done "$name"
    log "$name completed ✅"
}

get_latest_release() {
    curl --silent "https://api.github.com/repos/$1/releases/latest" | \
    grep '"tag_name":' | \
    sed -E 's/.*"([^"]+)".*/\1/'
}