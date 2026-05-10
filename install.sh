#!/usr/bin/env bash
set -euo pipefail

log()    { printf "[install] %s\n" "$*"; }
warn()   { printf "[install][warn] %s\n" "$*" >&2; }
die()    { printf "[install][error] %s\n" "$*" >&2; exit 1; }
need_cmd() { command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"; }

# ── Usage ──────────────────────────────────────────────────────────────
usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --dry-run         Print commands without executing
  --skip-packages   Skip pacman/yay package installation
  --skip-services   Skip enabling system services
  --skip-shell      Skip changing default shell to zsh
  -h, --help        Show this help
EOF
}

DRY_RUN=0
SKIP_PACKAGES=0
SKIP_SERVICES=0
SKIP_SHELL=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)       DRY_RUN=1 ;;
    --skip-packages) SKIP_PACKAGES=1 ;;
    --skip-services) SKIP_SERVICES=1 ;;
    --skip-shell)    SKIP_SHELL=1 ;;
    -h|--help)       usage; exit 0 ;;
    *)               die "Unknown option: $1" ;;
  esac
  shift
done

# ── Helpers ────────────────────────────────────────────────────────────
run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run] %q ' "$@"; printf '\n'; return 0
  fi
  "$@"
}

run_sudo() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run] sudo %q ' "$@"; printf '\n'; return 0
  fi
  sudo "$@"
}

# ── Paths ──────────────────────────────────────────────────────────────
DOTFILES_DIR=$(cd "$(dirname "$0")" && pwd)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$HOME/.config/dotfiles-backups/$TIMESTAMP"

# ── Dotfile linking ────────────────────────────────────────────────────
backup_target_if_needed() {
  local target="$1" desired="$2"

  # Nothing to back up if nothing exists
  [[ ! -e "$target" && ! -L "$target" ]] && return

  # Already the correct symlink
  if [[ -L "$target" ]]; then
    local current
    current=$(readlink "$target") || true
    [[ "$current" == "$desired" ]] && return
  fi

  run mkdir -p "$BACKUP_DIR"
  log "Backing up existing target: $target"
  run mv "$target" "$BACKUP_DIR/"
}

link_file() {
  local src="$1" dst="$2"
  backup_target_if_needed "$dst" "$src"
  run ln -sfn "$src" "$dst"
}

# ── Preflight ──────────────────────────────────────────────────────────
preflight() {
  need_cmd bash sudo git systemctl

  if [[ $EUID -eq 0 ]]; then
    die "Run this script as a normal user with sudo privileges, not root."
  fi

  if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    if [[ "${ID:-}" != "arch" && "${ID_LIKE:-}" != *"arch"* ]]; then
      warn "OS reports ID=${ID:-unknown}; this script is optimized for Arch Linux."
    fi
  else
    warn "Cannot read /etc/os-release to verify distro."
  fi

  if [[ "$DRY_RUN" -eq 0 ]]; then
    sudo -v
  else
    log "[dry-run] Skipping sudo credential check"
  fi
}

# ── yay ────────────────────────────────────────────────────────────────
install_yay_if_missing() {
  if command -v yay >/dev/null 2>&1; then
    log "yay is already installed"
    return
  fi

  log "Installing yay-bin from AUR"
  run_sudo pacman -Sy --needed --noconfirm git base-devel

  local temp_dir
  temp_dir=$(mktemp -d)
  run git clone https://aur.archlinux.org/yay-bin.git "$temp_dir/yay-bin"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] Would build and install yay-bin from $temp_dir/yay-bin"
  else
    pushd "$temp_dir/yay-bin" >/dev/null
    makepkg -si --noconfirm
    popd >/dev/null
  fi
  run rm -rf "$temp_dir"
}

# ── Packages ───────────────────────────────────────────────────────────
install_packages() {
  if [[ "$SKIP_PACKAGES" -eq 1 ]]; then
    log "Skipping package installation"
    return
  fi

  # Packages from the official repos
  local pacman_pkgs=(
    git base-devel jq pacman-contrib
    zsh fzf zoxide fastfetch starship
    go rustup npm rbenv python
    ly
    hyprland hypridle hyprlock waybar rofi-wayland wl-clipboard cliphist dunst polkit-gnome
    xdg-desktop-portal-hyprland xdg-desktop-portal xdg-desktop-portal-gtk qt5-wayland qt6-wayland
    pipewire pipewire-alsa pipewire-pulse wireplumber pavucontrol playerctl
    network-manager-applet blueman
    ghostty firefox thunar code spotify-launcher
    ttf-jetbrains-mono-nerd ttf-fira-code ttf-font-awesome noto-fonts-emoji papirus-icon-theme
    swappy grim slurp imagemagick qalculate-gtk xclip brightnessctl
    libnotify
  )

  # AUR packages (installed via yay)
  local aur_pkgs=(
    cozette-ttf
    zen-browser-bin
    webcord
    caffeine-ng
    awww
    pipx
    wlogout
  )

  # Resolve known package conflicts before installing.
  # On Arch, AUR / alternative packages can conflict with our repo targets.
  # Remove the alternatives so pacman can proceed without interactive prompts.
  local known_conflicts=(
    # (to_remove  reason)
    visual-studio-code-bin  "conflicts with code (pacman)"
    jack2                   "conflicts with pipewire-jack"
    rofi                    "conflicts with rofi-wayland"
    python-pipx             "repo pipx replaced by AUR pipx"
  )

  local i=0
  while (( i < ${#known_conflicts[@]} )); do
    local pkg="${known_conflicts[$i]}"
    local reason="${known_conflicts[$((i+1))]}"
    if pacman -Qi "$pkg" &>/dev/null 2>&1; then
      log "Removing $pkg ($reason)"
      run_sudo pacman -Rdd --noconfirm "$pkg" 2>/dev/null || true
    fi
    i=$(( i + 2 ))
  done

  # Install official repo packages.
  # yes | handles the "remove conflicting package?" prompt that
  # pacman --noconfirm deliberately does NOT auto-answer.
  log "Installing official repository packages"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    run pacman -Sy --needed --noconfirm "${pacman_pkgs[@]}"
  else
    run yes | sudo pacman -Sy --needed --noconfirm "${pacman_pkgs[@]}"
  fi

  install_yay_if_missing

  log "Installing AUR packages"
  run yay -S --needed --noconfirm "${aur_pkgs[@]}"
}

# ── Deploy dotfiles ────────────────────────────────────────────────────
deploy_dotfiles() {
  local config_pkgs=(
    hypr hyprfloat waybar rofi dunst wlogout
    swappy scripts apps ghostty fastfetch
    gtk-3.0 gtk-4.0
  )

  run mkdir -p "$HOME/.config"

  log "Linking config directories into ~/.config"
  for pkg in "${config_pkgs[@]}"; do
    if [[ -d "$DOTFILES_DIR/$pkg" ]]; then
      link_file "$DOTFILES_DIR/$pkg" "$HOME/.config/$pkg"
    else
      warn "Missing config directory: $pkg"
    fi
  done

  [[ -f "$DOTFILES_DIR/starship.toml" ]] \
    && link_file "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"

  [[ -f "$DOTFILES_DIR/zsh/.zshrc" ]] \
    && link_file "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"

  [[ -f "$DOTFILES_DIR/zsh/.zshenv" ]] \
    && link_file "$DOTFILES_DIR/zsh/.zshenv" "$HOME/.zshenv"
}

# ── Wallpaper ──────────────────────────────────────────────────────────
deploy_default_wallpaper() {
  if [[ -f "$HOME/Pictures/default.png" ]]; then
    log "Default wallpaper already exists at ~/Pictures/default.png"
    return
  fi

  local src="$DOTFILES_DIR/wallpapers/1920x1080-dark-linux.png"
  if [[ ! -f "$src" ]]; then
    warn "No default wallpaper found in repo wallpapers/"
    return
  fi

  run mkdir -p "$HOME/Pictures"
  run cp "$src" "$HOME/Pictures/default.png"
  log "Deployed default wallpaper to ~/Pictures/default.png"
}

# ── Services ───────────────────────────────────────────────────────────
enable_services() {
  if [[ "$SKIP_SERVICES" -eq 1 ]]; then
    log "Skipping service enablement"
    return
  fi

  local services=(
    ly.service
    NetworkManager.service
    bluetooth.service
  )

  log "Ensuring required services are enabled"
  for service in "${services[@]}"; do
    if [[ "$DRY_RUN" -eq 1 ]]; then
      log "[dry-run] sudo systemctl enable $service"
      continue
    fi

    if systemctl is-enabled --quiet "$service"; then
      log "  $service already enabled"
    else
      run_sudo systemctl enable "$service"
    fi
  done
}

# ── Shell ──────────────────────────────────────────────────────────────
set_default_shell() {
  if [[ "$SKIP_SHELL" -eq 1 ]]; then
    log "Skipping shell change"
    return
  fi

  need_cmd zsh
  local zsh_path
  zsh_path=$(command -v zsh)

  if [[ "$SHELL" == "$zsh_path" ]]; then
    log "Default shell already set to zsh"
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] chsh -s $zsh_path"
    return
  fi

  log "Changing default shell to zsh"
  chsh -s "$zsh_path"
}

# ── Postflight ─────────────────────────────────────────────────────────
postflight() {
  cat <<EOF

[install] Completed.

Next checks:
  - hyprctl systeminfo | head -n 20
  - systemctl is-enabled ly NetworkManager bluetooth
  - ls -l ~/.config/hypr ~/.config/waybar ~/.config/rofi ~/.zshrc ~/.zshenv

If this was a fresh install, reboot before first Hyprland login.

Backup location for replaced files:
  $BACKUP_DIR
EOF
}

# ── Main ───────────────────────────────────────────────────────────────
main() {
  log "Using dotfiles directory: $DOTFILES_DIR"
  preflight
  install_packages
  deploy_dotfiles
  deploy_default_wallpaper
  enable_services
  set_default_shell
  postflight
}

main "$@"
