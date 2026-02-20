#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

source "$ROOT_DIR/lib.sh"

install_base() {
    sudo apt update && sudo apt upgrade -y

    sudo apt install -y \
        arandr flameshot arc-theme feh i3blocks i3status i3 lxappearance \
        python3-pip python3-venv rofi unclutter xclip \
        papirus-icon-theme imagemagick \
        libxcb-shape0-dev libxcb-keysyms1-dev libpango1.0-dev \
        libxcb-util0-dev libxcb1-dev libxcb-icccm4-dev libyajl-dev \
        libev-dev libxcb-xkb-dev libxkbcommon-dev \
        libxcb-xinerama0-dev libxkbcommon-x11-dev \
        libstartup-notification0-dev libxcb-randr0-dev \
        libxcb-xrm0 libxcb-xrm-dev autoconf meson \
        libxcb-render-util0-dev libxcb-xfixes0-dev \
        curl vim zsh bash-completion golang-go \
        tmux jq hexyl fd-find bat unzip wget snapd
}

run_step base install_base
