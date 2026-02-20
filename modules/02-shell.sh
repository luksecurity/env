#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

source "$ROOT_DIR/lib.sh"

install_zsh() {
    if ! command -v zsh &>/dev/null; then
        sudo apt update
        sudo apt install -y zsh
    fi

    if [ "$SHELL" != "$(command -v zsh)" ]; then
        chsh -s "$(command -v zsh)"
        log "Default shell changed to zsh (logout required)"
    fi
}

install_oh_my_zsh() {
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        RUNZSH=no CHSH=no sh -c \
            "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    fi
}

install_fzf() {
    if [ ! -d "$HOME/.fzf" ]; then
        git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    else
        (cd "$HOME/.fzf" && git pull) || true
    fi

    "$HOME/.fzf/install" --all
}

run_step zsh install_zsh
run_step ohmyzsh install_oh_my_zsh
run_step fzf install_fzf
