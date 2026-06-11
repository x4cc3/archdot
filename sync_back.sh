#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/.config/dotfiles"
CONFIG_DIRS=(
  hypr hyprfloat waybar rofi dunst wlogout swappy scripts ghostty fastfetch gtk-4.0 zed xsettingsd
)

for dir in "${CONFIG_DIRS[@]}"; do
  if [ -d "$HOME/.config/$dir" ]; then
    echo "Syncing $dir..."
    rsync -av --delete "$HOME/.config/$dir/" "$DOTFILES_DIR/$dir/"
  fi
done

# Sync individual files
[ -f "$HOME/.config/starship.toml" ] && cp -a "$HOME/.config/starship.toml" "$DOTFILES_DIR/starship.toml"
[ -f "$HOME/.zshrc" ] && cp -a "$HOME/.zshrc" "$DOTFILES_DIR/zsh/.zshrc"
[ -f "$HOME/.zshenv" ] && cp -a "$HOME/.zshenv" "$DOTFILES_DIR/zsh/.zshenv"
[ -f "$HOME/.config/gtkrc" ] && cp -a "$HOME/.config/gtkrc" "$DOTFILES_DIR/gtkrc"
[ -f "$HOME/.config/gtkrc-2.0" ] && cp -a "$HOME/.config/gtkrc-2.0" "$DOTFILES_DIR/gtkrc-2.0"

# Sync gtk-3.0
if [ -d "$HOME/.config/gtk-3.0" ]; then
    echo "Syncing gtk-3.0..."
    rsync -av --delete "$HOME/.config/gtk-3.0/" "$DOTFILES_DIR/gtk-3.0/"
fi

echo "Done syncing back to dotfiles."
