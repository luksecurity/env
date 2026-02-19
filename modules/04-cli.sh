#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

source "$ROOT_DIR/lib.sh"

install_modern_tools() {

    export PATH="$HOME/.cargo/bin:$PATH"
    for tool in bottom procs git-delta du-dust navi; do
        cargo install "$tool" || true
    done

    export PATH="$HOME/go/bin:$PATH"
    go install github.com/charmbracelet/glow@latest || true
    go install github.com/tomnom/gron@latest || true

    [ -d ~/.asdf ] || git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.10.2
    [ -d ~/.ptf ] || git clone https://github.com/mubix/ptf ~/.ptf

    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
}

run_step devtools install_modern_tools