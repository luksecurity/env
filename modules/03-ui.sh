#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

source "$ROOT_DIR/lib.sh"

install_fonts() {
    log "Installing Nerd Fonts..."

    local VERSION
    VERSION=$(get_latest_release "ryanoasis/nerd-fonts")

    log "Latest version: $VERSION"

    mkdir -p ~/.local/share/fonts/

    for font in Iosevka RobotoMono; do
        log "Downloading $font..."
        wget -q --show-progress \
            "https://github.com/ryanoasis/nerd-fonts/releases/download/${VERSION}/${font}.zip"

        log "Extracting $font..."
        unzip -o "${font}.zip" -d ~/.local/share/fonts/ >/dev/null

        rm "${font}.zip"
        log "$font installed ✅"
    done

    log "Refreshing font cache..."
    fc-cache -fv >/dev/null

    log "Fonts installation complete ✅"
}

install_alacritty() {
    if command -v alacritty &>/dev/null; then
        return
    fi

    URL=$(curl -s https://api.github.com/repos/barnumbirr/alacritty-debian/releases/latest | \
        grep "browser_download_url.*amd64_bullseye.deb" | cut -d '"' -f 4 | head -n 1)

    wget "$URL"
    sudo dpkg -i *.deb || sudo apt install -f -y
    rm *.deb
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

    feh --bg-fill "$DEST"

    log "Wallpaper applied ✅"
}

run_step fonts install_fonts
run_step alacritty install_alacritty
run_step wallpaper install_wallpaper
