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
        curl -fsSL https://sh.rustup.rs | sh -s -- -y
    fi

    # Load cargo env safely
    if [ -f "$HOME/.cargo/env" ]; then
        # shellcheck disable=SC1090
        source "$HOME/.cargo/env"
    fi

    export PATH="$HOME/.cargo/bin:$PATH"

    log "Updating Rust toolchain..."
    rustup update || log "Rust update failed (continuing)"
}

install_go_env() {
    if ! command -v go &>/dev/null; then
        log "Go not found. Install Go first."
        exit 1
    fi

    log "Configuring Go proxy..."
    go env -w GOPROXY="https://proxy.golang.org,direct"
    go env -w GOSUMDB="sum.golang.org"
}

install_modern_tools() {

    log "Installing Rust toolchain..."
    install_rust

    log "Installing Rust CLI tools..."
    for tool in bottom procs git-delta du-dust navi; do
        if command -v "$tool" &>/dev/null; then
            log "$tool already installed"
        else
            log "Installing $tool..."
            cargo install "$tool" || log "Failed to install $tool (continuing)"
        fi
    done

    log "Installing Go tools..."
    install_go_env

    export PATH="$HOME/go/bin:$PATH"

    for tool in \
        github.com/charmbracelet/glow@latest \
        github.com/tomnomnom/gron@latest; do

        log "Installing $(basename "$tool")..."
        go install "$tool" || log "Failed: $tool"
    done

    log "Installing asdf..."
    if [ ! -d "$HOME/.asdf" ]; then
        git clone https://github.com/asdf-vm/asdf.git "$HOME/.asdf" --branch v0.13.1
    else
        log "asdf already installed"
    fi

    log "Installing ptf..."
    if [ ! -d "$HOME/.ptf" ]; then
        git clone https://github.com/mubix/ptf "$HOME/.ptf"
    else
        log "ptf already installed"
    fi

    log "Installing zoxide..."
    if ! command -v zoxide &>/dev/null; then
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    else
        log "zoxide already installed"
    fi

    log "Ensuring ~/.local/bin is in PATH..."
    if ! grep -q '.local/bin' "$HOME/.zshrc" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
    fi

    log "Devtools installation complete ✅"
}

run_step devtools install_modern_tools
