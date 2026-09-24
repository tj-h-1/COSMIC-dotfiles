#!/usr/bin/env bash

set -e

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.local/state/dotfiles-COSMIC-backup/$(date +%Y%m%d-%H%M%S)"
OLD_HOME="/home/tj-h-1"

echo "=== COSMIC Fedora Setup ==="
echo "Dotfiles: $DOTFILES"
echo "Backup:   $BACKUP"
echo

# ------------------------------------------------------------
# Check distro
# ------------------------------------------------------------

if [ ! -f /etc/fedora-release ]; then
    echo "WARNING: This installer is intended for Fedora."
    read -r -p "Continue anyway? [y/N] " answer

    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# ------------------------------------------------------------
# Packages
# ------------------------------------------------------------

echo "Installing Fedora packages..."

sudo dnf install -y \
    git \
    kitty \
    fontconfig \
    curl \
    cargo \
    rust

# ------------------------------------------------------------
# Matugen
# ------------------------------------------------------------

export PATH="$HOME/.cargo/bin:$PATH"

if command -v matugen >/dev/null 2>&1; then
    echo "Matugen is already installed."
else
    echo "Installing Matugen..."
    cargo install matugen
fi

# ------------------------------------------------------------
# Directories
# ------------------------------------------------------------

mkdir -p "$BACKUP"
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.local/share/fonts"
mkdir -p "$HOME/.local/share/icons"
mkdir -p "$HOME/Pictures"

# ------------------------------------------------------------
# Backups
# ------------------------------------------------------------

backup_config() {
    local name="$1"

    if [ -e "$HOME/.config/$name" ]; then
        echo "Backing up ~/.config/$name"
        cp -a "$HOME/.config/$name" "$BACKUP/"
    fi
}

backup_config cosmic
backup_config kitty
backup_config matugen
backup_config fontconfig

# ------------------------------------------------------------
# COSMIC
# ------------------------------------------------------------

echo "Installing COSMIC configuration..."

mkdir -p "$HOME/.config/cosmic"

cp -a \
    "$DOTFILES/config/cosmic/." \
    "$HOME/.config/cosmic/"

# ------------------------------------------------------------
# Kitty
# ------------------------------------------------------------

echo "Installing Kitty configuration..."

rm -rf "$HOME/.config/kitty"
cp -a "$DOTFILES/config/kitty" "$HOME/.config/kitty"

# ------------------------------------------------------------
# Matugen
# ------------------------------------------------------------

echo "Installing Matugen configuration..."

rm -rf "$HOME/.config/matugen"
cp -a "$DOTFILES/config/matugen" "$HOME/.config/matugen"

# ------------------------------------------------------------
# Fontconfig
# ------------------------------------------------------------

echo "Installing Fontconfig configuration..."

rm -rf "$HOME/.config/fontconfig"
cp -a "$DOTFILES/config/fontconfig" "$HOME/.config/fontconfig"

# ------------------------------------------------------------
# MonoCraft
# ------------------------------------------------------------

echo "Installing MonoCraft..."

cp -a \
    "$DOTFILES/local/share/fonts/." \
    "$HOME/.local/share/fonts/"

# ------------------------------------------------------------
# Local scripts
# ------------------------------------------------------------

echo "Installing local scripts..."

cp -a \
    "$DOTFILES/local/bin/." \
    "$HOME/.local/bin/"

chmod +x "$HOME/.local/bin/theme"

# ------------------------------------------------------------
# Optional icon themes
# ------------------------------------------------------------

if [ -d "$DOTFILES/local/share/icons" ]; then
    echo "Installing icon themes..."

    cp -a \
        "$DOTFILES/local/share/icons/." \
        "$HOME/.local/share/icons/"
fi

# ------------------------------------------------------------
# Wallpapers
# ------------------------------------------------------------

echo "Installing wallpapers..."

if [ -d "$HOME/Pictures/wallpapers/.git" ]; then

    echo "Wallpaper repository already exists."
    echo "Updating..."

    git -C "$HOME/Pictures/wallpapers" pull

else

    if [ -e "$HOME/Pictures/wallpapers" ]; then
        echo "Backing up existing wallpaper directory..."

        mv \
            "$HOME/Pictures/wallpapers" \
            "$BACKUP/wallpapers"
    fi

    git clone \
        https://github.com/tj-h-1/wallpapers.git \
        "$HOME/Pictures/wallpapers"

fi

# ------------------------------------------------------------
# Fix paths copied from old installation
# ------------------------------------------------------------

echo "Updating absolute home-directory paths..."

find \
    "$HOME/.config/cosmic" \
    "$HOME/.config/matugen" \
    -type f \
    -exec sed -i "s#$OLD_HOME#$HOME#g" {} \;

# ------------------------------------------------------------
# PATH
# ------------------------------------------------------------

if ! grep -Fq 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null; then

    echo >> "$HOME/.bashrc"
    echo '# dotfiles-COSMIC' >> "$HOME/.bashrc"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"

fi

if ! grep -Fq 'export PATH="$HOME/.cargo/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null; then

    echo '# Cargo' >> "$HOME/.bashrc"
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$HOME/.bashrc"

fi

# ------------------------------------------------------------
# Font cache
# ------------------------------------------------------------

echo "Refreshing font cache..."

fc-cache -f

# ------------------------------------------------------------
# Finish
# ------------------------------------------------------------

echo
echo "======================================"
echo "COSMIC configuration installed."
echo "======================================"
echo
echo "Backup:"
echo "$BACKUP"
echo
echo "Log out and back into COSMIC."
echo

