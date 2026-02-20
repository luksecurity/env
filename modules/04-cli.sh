#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

source "$ROOT_DIR/lib.sh"

install_rust() {
    if command -v rustc &>/dev/null; then
        log "Rust already installed"
    else
        log "Installing Rust via rustup..."
        curl https://sh.rustup.rs -sSf | sh -s -- -y
    fi

    # Load cargo env
    source "$HOME/.cargo/env"

    log "Updating Rust toolchain..."
    rustup update
}

install_go_env() {
    if ! command -v go &>/dev/null; then
        log "Go not found. Please install Go first."
        exit 1
    fi

    export GOPROXY="https://proxy.golang.org,direct"
    go env -w GOPROXY="https://proxy.golang.org,direct"
}

install_modern_tools() {

    log "Installing Rust toolchain..."
    install_rust

    export PATH="$HOME/.cargo/bin:$PATH"

    log "Installing Rust CLI tools..."
    for tool in bottom procs git-delta du-dust navi; do
        log "Installing $tool..."
        cargo install "$tool" || log "Failed to install $tool (continuing)"
    done

    log "Installing Go tools..."
    install_go_env

    export PATH="$HOME/go/bin:$PATH"

    go install github.com/charmbracelet/glow@latest || log "Glow failed"
    go install github.com/tomnomnom/gron@latest || log "Gron failed"

    log "Installing asdf..."
    [ -d ~/.asdf ] || git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.13.1

    log "Installing ptf..."
    [ -d ~/.ptf ] || git clone https://github.com/mubix/ptf ~/.ptf

    log "Installing zoxide..."
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

    log "Adding ~/.local/bin to PATH if missing..."
    if ! grep -q '.local/bin' ~/.zshrc 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
    fi

    log "Devtools installation complete ✅"
}

run_step devtools install_modern_tools
