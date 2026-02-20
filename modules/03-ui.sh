#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

source "$ROOT_DIR/lib.sh"

mkdir -p ~/.config/{i3,compton,rofi,alacritty}

cp -r .config/* ~/.config/
cp .fehbg ~/
cp -r .wallpaper ~/

install_fonts() {
    log "Installing Nerd Fonts..."

    local VERSION
    VERSION=$(get_latest_release "ryanoasis/nerd-fonts") || return

    mkdir -p "$HOME/.local/share/fonts"

    for font in Iosevka RobotoMono; do
        wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/${VERSION}/${font}.zip"
        unzip -o "${font}.zip" -d "$HOME/.local/share/fonts"
        rm -f "${font}.zip"
    done

    fc-cache -fv
}

install_alacritty() {
    if command -v alacritty &>/dev/null; then
        return
    fi

    log "Installing Alacritty..."

    local URL
    URL=$(curl -s https://api.github.com/repos/barnumbirr/alacritty-debian/releases/latest | \
        grep "browser_download_url.*amd64_bullseye.deb" | cut -d '"' -f 4 | head -n 1)

    if [ -z "$URL" ]; then
        log "Failed to fetch Alacritty URL"
        return
    fi

    local TMP_DEB="/tmp/alacritty.deb"

    wget -O "$TMP_DEB" "$URL"
    sudo dpkg -i "$TMP_DEB" || sudo apt install -f -y
    rm -f "$TMP_DEB"
}

install_wallpaper() {
    log "Setting wallpaper..."

    local SRC="$ROOT_DIR/assets/wallpaper/23.jpg"
    local DEST_DIR="$HOME/.wallpaper"
    local DEST="$DEST_DIR/23.jpg"

    if [ ! -f "$SRC" ]; then
        log "Wallpaper not found."
        return
    fi

    mkdir -p "$DEST_DIR"

    if [ ! -f "$DEST" ] || ! cmp -s "$SRC" "$DEST"; then
        cp "$SRC" "$DEST"
        log "Wallpaper copied."
    fi

    # Install feh if missing
    if ! command -v feh &>/dev/null; then
        sudo apt install -y feh
    fi

    feh --bg-fill "$DEST"

    # Make persistent in i3
    local I3_CONFIG="$HOME/.config/i3/config"
    mkdir -p "$(dirname "$I3_CONFIG")"

    if ! grep -q "exec_always --no-startup-id ~/.fehbg" "$I3_CONFIG" 2>/dev/null; then
        echo 'exec_always --no-startup-id ~/.fehbg' >> "$I3_CONFIG"
        log "Wallpaper persistence added to i3 config"
    fi

    log "Wallpaper applied ✅"
}

run_step fonts install_fonts
run_step alacritty install_alacritty
run_step wallpaper install_wallpaper
