#!/bin/bash
set -euo pipefail

# Sudo Keep-Alive
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Configuration
LOG_FILE="install.log"
PROGRESS_FILE=".install.progress"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# URLs
FZF_URL="https://github.com/junegunn/fzf.git"
DOCKER_URL="https://get.docker.com/"

# Colors
GREEN='\033[1;32m'
RED='\033[0;31m'
NC='\033[0m'

# Helper Functions
log() {
    echo -e "${GREEN}[+]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

get_latest_release() {
    curl --silent "https://api.github.com/repos/$1/releases/latest" | \
    grep '"tag_name":' | \
    sed -E 's/.*"([^"]+)".*/\1/'
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >> "$LOG_FILE"
}

step() {
    local percentage=$1
    local message=$2
    local func_to_run=$3

    # Check if step is already completed
    if grep -Fxq "$message" "$PROGRESS_FILE" 2>/dev/null; then
        echo -e "${GREEN}[SKIP]${NC} $message (already completed)"
        return
    fi
    
    local bar_length=$((percentage / 2))
    local bar=$(printf "%-${bar_length}s" | tr ' ' '#')
    local percentage_text="($percentage%)"
    
    echo -e "\r${GREEN}[+]${NC} $message\n$bar $percentage_text"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] STEP: $message ($percentage%)" >> "$LOG_FILE"
    
    if $func_to_run; then
        echo "$message" >> "$PROGRESS_FILE"
    else
        local exit_code=$?
        error "Step failed: $message (Exit code: $exit_code)"
        sed -i "/$message/d" "$PROGRESS_FILE" 2>/dev/null || true
        exit $exit_code
    fi
}

check_command() {
    command -v "$1" &> /dev/null
}

# Main install

install_base() {
    log "Updating system and installing base dependencies..."
    sudo apt update && sudo apt upgrade -y
    
    local packages=(
        arandr flameshot arc-theme feh i3blocks i3status i3 i3-wm lxappearance 
        python3-pip rofi unclutter cargo compton papirus-icon-theme imagemagick
        libxcb-shape0-dev libxcb-keysyms1-dev libpango1.0-dev libxcb-util0-dev 
        xcb libxcb1-dev libxcb-icccm4-dev libyajl-dev libev-dev libxcb-xkb-dev 
        libxkbcommon-dev libxcb-xinerama0-dev libxkbcommon-x11-dev 
        libstartup-notification0-dev libxcb-randr0-dev libxcb-xrm0 libxcb-xrm-dev 
        autoconf meson libxcb-render-util0-dev libxcb-xfixes0-dev 
        curl vim zsh python3-venv bash-completion golang-go
        tmux jq hexyl fd-find bat
    )
    
    sudo apt-get install -yq "${packages[@]}"
}

install_fonts() {
    log "Fetching latest Nerd Fonts version..."
    local NERD_FONT_VERSION=$(get_latest_release "ryanoasis/nerd-fonts")
    log "Latest Nerd Fonts version: $NERD_FONT_VERSION"

    log "Installing fonts..."
    mkdir -p ~/.local/share/fonts/
    
    local fonts=("Iosevka" "RobotoMono")
    for font in "${fonts[@]}"; do
        if [ ! -f ~/.local/share/fonts/$font/complete ]; then 
            if [ -f "${font}.zip" ]; then
                log "Found existing ${font}.zip, skipping download."
            else
                log "Downloading $font ($NERD_FONT_VERSION)... this may take a while."
                wget --show-progress "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONT_VERSION}/${font}.zip"
            fi
            
            unzip -o "${font}.zip" -d ~/.local/share/fonts/
            touch ~/.local/share/fonts/$font/complete # Create marker
            rm "${font}.zip"
        else
            log "Font $font likely already installed."
        fi
    done
    
    fc-cache -fv
}

install_alacritty() {
    log "Fetching latest Alacritty version..."
    local ALACRITTY_TAG=$(get_latest_release "barnumbirr/alacritty-debian")
    local ALACRITTY_VERSION=${ALACRITTY_TAG#v}
    local DOWNLOAD_URL=$(curl -s "https://api.github.com/repos/barnumbirr/alacritty-debian/releases/latest" | grep "browser_download_url.*amd64_bullseye.deb" | cut -d '"' -f 4 | head -n 1)
    local DEB_NAME=$(basename "$DOWNLOAD_URL")

    log "Latest Alacritty deb: $DEB_NAME"

    log "Installing Alacritty..."
    if ! check_command alacritty; then
        if [ -z "$DOWNLOAD_URL" ]; then
            error "Could not find Alacritty deb url!"
            return 1
        fi
        wget -q "$DOWNLOAD_URL"
        sudo dpkg -i "$DEB_NAME" || sudo apt install -f -y
        rm "$DEB_NAME"
    else
        log "Alacritty already installed."
    fi
}

install_fzf() {
    log "Installing fzf..."
    if [ ! -d ~/.fzf ]; then
        git clone --depth 1 "$FZF_URL" ~/.fzf
        ~/.fzf/install --all
    else
        log "fzf already installed."
    fi
}

install_docker() {
    log "Installing Docker..."
    if ! check_command docker; then
        curl -fsSL "$DOCKER_URL" -o get-docker.sh
        sed -i 's/-qq//g' get-docker.sh
        sed -i 's/>\/dev\/null//g' get-docker.sh
        
        sh get-docker.sh
        rm get-docker.sh
    else
        log "Docker already installed."
    fi
}

install_exegol() {
    log "Installing Exegol..."
    if ! check_command pipx; then
        log "Installing pipx..."
        sudo apt-get install -y pipx || python3 -m pip install --user pipx --break-system-packages
        
        pipx ensurepath
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    if ! pipx list | grep -q 'exegol'; then
        pipx install exegol

        if getent group docker >/dev/null; then
             sudo usermod -aG docker "$USER"
             log "User added to docker group. Please logout/login later."
        fi
        
        if check_command register-python-argcomplete; then
            register-python-argcomplete --no-defaults exegol | sudo tee /etc/bash_completion.d/exegol > /dev/null
        fi
    else
        log "Exegol already installed."
    fi
}

install_vscode() {
    log "Installing VSCode..."
    sudo snap install --classic code
    
    log "Restoring VSCode settings..."
    mkdir -p ~/.config/Code/User/
    mkdir -p ~/.vscode/extensions/
    
    if [ -f "$HOME/vscode/settings.json" ]; then
        cp "$HOME/vscode/settings.json" ~/.config/Code/User/settings.json
    fi
    
    if [ -d "$HOME/vscode/extensions" ]; then
        cp -r "$HOME/vscode/extensions/"* ~/.vscode/extensions/
    fi
}

setup_env() {
    log "Setting up environment..."
    pip3 install --user pywal
    
    mkdir -p ~/.config/{i3,compton,rofi,alacritty}
    
    [ -f "$SCRIPT_DIR/.config/i3/config" ] && cp "$SCRIPT_DIR/.config/i3/config" ~/.config/i3/config
    [ -f "$SCRIPT_DIR/.config/alacritty/alacritty.yml" ] && cp "$SCRIPT_DIR/.config/alacritty/alacritty.yml" ~/.config/alacritty/alacritty.yml
    [ -f "$SCRIPT_DIR/.config/i3/i3blocks.conf" ] && cp "$SCRIPT_DIR/.config/i3/i3blocks.conf" ~/.config/i3/i3blocks.conf
    [ -f "$SCRIPT_DIR/.config/compton/compton.conf" ] && cp "$SCRIPT_DIR/.config/compton/compton.conf" ~/.config/compton/compton.conf
    [ -f "$SCRIPT_DIR/.config/rofi/config" ] && cp "$SCRIPT_DIR/.config/rofi/config" ~/.config/rofi/config
    
    [ -f "$SCRIPT_DIR/.fehbg" ] && cp "$SCRIPT_DIR/.fehbg" ~/.fehbg
    [ -f "$SCRIPT_DIR/.config/i3/clipboard_fix.sh" ] && cp "$SCRIPT_DIR/.config/i3/clipboard_fix.sh" ~/.config/i3/clipboard_fix.sh
    
    [ -d "$SCRIPT_DIR/.wallpaper" ] && cp -r "$SCRIPT_DIR/.wallpaper" ~/.wallpaper
}

install_i3_gaps() {
    log "Installing i3-gaps..."
    if [ ! -d "i3-gaps" ]; then
        git clone https://www.github.com/Airblader/i3 i3-gaps
        cd i3-gaps
        mkdir -p build && cd build
        meson ..
        ninja
        sudo ninja install
        cd ../..
        rm -rf i3-gaps
    else
        log "i3-gaps build folder exists. Skipping clone."
    fi
}

install_oh_my_zsh() {
    log "Installing Oh My Zsh..."
    if [ ! -d ~/.oh-my-zsh ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
    
    local ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
    
    [ ! -d "${ZSH_CUSTOM}/plugins/zsh-completions" ] && git clone https://github.com/zsh-users/zsh-completions "${ZSH_CUSTOM}/plugins/zsh-completions"
    [ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ] && git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
    [ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
}

install_modern_tools() {
    log "Installing modern CLI tools..."
    
    if check_command fdfind; then
        sudo ln -sf "$(which fdfind)" /usr/local/bin/fd || true
        log "Aliased fdfind to fd."
    fi
    if check_command batcat; then
        sudo ln -sf "$(which batcat)" /usr/local/bin/bat || true
        log "Aliased batcat to bat."
    fi

    # Cargo tools
    export PATH="$HOME/.cargo/bin:$PATH"
    
    local cargo_tools=(
        bottom      
        procs
        git-delta   
        du-dust     
        navi
    )
    
    for tool in "${cargo_tools[@]}"; do
        local bin_name="$tool"
        case "$tool" in
            bottom) bin_name="btm" ;;
            git-delta) bin_name="delta" ;;
            du-dust) bin_name="dust" ;;
        esac

        if ! command -v "$bin_name" &> /dev/null; then
             log "Installing $tool via Cargo..."
             cargo install "$tool" || log "Failed to install $tool via Cargo."
        else
             log "$tool seems installed."
        fi
    done

    # Go Tools
    export PATH="$HOME/go/bin:$PATH"
    if check_command go; then
        log "Installing Go tools (glow, gron)..."
        if ! command -v glow &> /dev/null; then
            go install github.com/charmbracelet/glow@latest || log "Failed to install glow."
        fi
        if ! command -v gron &> /dev/null; then
            go install github.com/tomnom/gron@latest || log "Failed to install gron."
        fi
    else
        error "Go is not installed, skipping Go tools."
    fi

    # Git tools
    if [ ! -d ~/.asdf ]; then
        log "Installing asdf..."
        git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.10.2
    fi

    if [ ! -d ~/.ptf ]; then
        log "Installing PTF..."
        git clone https://github.com/mubix/ptf ~/.ptf
    fi

    if ! check_command zoxide; then
        log "Installing zoxide..."
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    fi
}

# Run

step 10 "Installing base" install_base
step 25 "Installing fonts" install_fonts
step 40 "Installing alacritty" install_alacritty
step 50 "Installing fzf" install_fzf
step 55 "Installing docker" install_docker
step 60 "Installing exegol & pipx" install_exegol
step 80 "Installing vscode" install_vscode
step 90 "Env settings" setup_env
step 92 "Installing i3-gaps" install_i3_gaps
step 95 "Installing Oh My Zsh" install_oh_my_zsh
step 98 "Installing Modern Tools" install_modern_tools

echo -e "\r${GREEN}[+]${NC} Installation complete! :)"
log "Installation finished successfully."
