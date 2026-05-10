#!/usr/bin/env bash
set -Eeuo pipefail

log()  { printf '[install] %s\n' "$*"; }
warn() { printf '[install][warn] %s\n' "$*" >&2; }
die()  { printf '[install][error] %s\n' "$*" >&2; exit 1; }

DRY_RUN=0
SKIP_PACKAGES=0
SKIP_SERVICES=0
SKIP_SHELL=0
ENABLE_LY=0

usage() {
  cat <<'USAGE'
Usage: ./install.sh [options]

Options:
  --dry-run          Print commands without executing
  --skip-packages    Skip pacman/yay package installation
  --skip-services    Skip enabling system services
  --skip-shell       Skip changing default shell to zsh
  --enable-ly        Enable ly display manager service
  -h, --help         Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --skip-packages) SKIP_PACKAGES=1 ;;
    --skip-services) SKIP_SERVICES=1 ;;
    --skip-shell) SKIP_SHELL=1 ;;
    --enable-ly) ENABLE_LY=1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
  shift
done

run() {
  if (( DRY_RUN )); then
    printf '[dry-run]'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi
  "$@"
}

run_sudo() {
  if (( DRY_RUN )); then
    printf '[dry-run] sudo'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi
  sudo "$@"
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$HOME/.config/dotfiles-backups/$TIMESTAMP"

preflight() {
  [[ ${EUID:-$(id -u)} -ne 0 ]] || die "Run this as your normal user, not root."

  need_cmd bash
  need_cmd sudo
  need_cmd git

  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    if [[ "${ID:-}" != "arch" && "${ID_LIKE:-}" != *arch* ]]; then
      warn "This installer is meant for Arch/Arch-based systems. Detected: ${ID:-unknown}"
    fi
  else
    warn "Cannot read /etc/os-release; skipping distro check."
  fi

  if (( ! DRY_RUN )); then
    sudo -v
  fi
}

# Resolve to a real absolute path for comparison.
# Follows symlinks to find the actual file the link points to.
resolve_path() {
  realpath -- "$1" 2>/dev/null || echo "$1"
}

backup_target_if_needed() {
  local target="$1"
  local desired="$2"

  [[ -e "$target" || -L "$target" ]] || return 0

  if [[ -L "$target" ]]; then
    local current_resolved desired_resolved
    current_resolved="$(resolve_path "$target")"
    desired_resolved="$(resolve_path "$desired")"
    [[ "$current_resolved" == "$desired_resolved" ]] && return 0
  fi

  run mkdir -p "$BACKUP_DIR"
  log "Backing up $target -> $BACKUP_DIR/"
  run mv -- "$target" "$BACKUP_DIR/"
}

link_path() {
  local src="$1"
  local dst="$2"

  if [[ ! -e "$src" ]]; then
    warn "Missing source: $src"
    return 0
  fi

  backup_target_if_needed "$dst" "$src"

  # Create a relative symlink so the dotfiles work regardless of where
  # the repo is cloned or what the user's home directory is.
  local rel_src
  rel_src="$(realpath --relative-to="$(dirname -- "$dst")" -- "$src")"
  run ln -sfn -- "$rel_src" "$dst"
}

install_yay_if_missing() {
  command -v yay >/dev/null 2>&1 && { log "yay already installed"; return 0; }

  log "Installing yay-bin from AUR"
  run_sudo pacman -S --needed --noconfirm git base-devel

  local tmp
  tmp="$(mktemp -d)"
  run git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"

  if (( DRY_RUN )); then
    log "[dry-run] Would run makepkg -si in $tmp/yay-bin"
  else
    (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
  fi

  run rm -rf -- "$tmp"
}

install_packages() {
  (( SKIP_PACKAGES )) && { log "Skipping package installation"; return 0; }

  need_cmd pacman

  local pacman_pkgs=(
    git base-devel jq pacman-contrib
    zsh fzf zoxide fastfetch starship
    go rustup npm rbenv python python-pipx
    hyprland hypridle hyprlock
    waybar rofi-wayland wl-clipboard cliphist dunst
    polkit-gnome xdg-desktop-portal-hyprland xdg-desktop-portal xdg-desktop-portal-gtk
    qt5-wayland qt6-wayland
    pipewire pipewire-alsa pipewire-pulse wireplumber pavucontrol playerctl
    network-manager-applet blueman bluez bluez-utils
    ghostty firefox thunar code spotify-launcher
    ttf-jetbrains-mono-nerd ttf-fira-code ttf-font-awesome noto-fonts noto-fonts-emoji papirus-icon-theme
    swappy grim slurp imagemagick qalculate-gtk xclip brightnessctl libnotify
  )

  local aur_pkgs=(
    cozette-ttf
    zen-browser-bin
    webcord
    caffeine-ng
    wlogout
    awww
  )

  if (( ENABLE_LY )); then
    pacman_pkgs+=(ly)
  fi

  # Known conflicting packages that pacman --noconfirm will not auto-remove.
  # Remove them explicitly before installing our targets.
  local known_conflicts=(
    visual-studio-code-bin
    jack2
    rofi
  )
  local pkg
  for pkg in "${known_conflicts[@]}"; do
    if pacman -Qi "$pkg" &>/dev/null 2>&1; then
      log "Removing conflicting package: $pkg"
      run_sudo pacman -R --noconfirm "$pkg" 2>/dev/null || true
    fi
  done

  log "Installing official packages"
  if (( DRY_RUN )); then
    run pacman -Syu --needed --noconfirm "${pacman_pkgs[@]}"
  else
    # yes | handles "remove conflicting package?" prompts that
    # pacman --noconfirm deliberately does NOT auto-answer.
    run yes | sudo pacman -Syu --needed --noconfirm "${pacman_pkgs[@]}"
  fi

  install_yay_if_missing

  log "Installing AUR packages"
  run yay -S --needed --noconfirm "${aur_pkgs[@]}"
}

deploy_dotfiles() {
  local config_dirs=(
    hypr hyprfloat waybar rofi dunst wlogout swappy scripts apps ghostty fastfetch gtk-3.0 gtk-4.0
  )

  run mkdir -p "$HOME/.config"

  log "Linking config directories"
  local dir
  for dir in "${config_dirs[@]}"; do
    link_path "$DOTFILES_DIR/$dir" "$HOME/.config/$dir"
  done

  link_path "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"
  link_path "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
  link_path "$DOTFILES_DIR/zsh/.zshenv" "$HOME/.zshenv"

  if [[ -d "$DOTFILES_DIR/scripts" ]]; then
    run find "$DOTFILES_DIR/scripts" -type f -name '*.sh' -exec chmod +x {} +
  fi
}

deploy_default_wallpaper() {
  local dst="$HOME/Pictures/default.png"
  local src="$DOTFILES_DIR/wallpapers/1920x1080-dark-linux.png"

  [[ -f "$dst" ]] && { log "Default wallpaper already exists"; return 0; }
  [[ -f "$src" ]] || { warn "Default wallpaper not found: $src"; return 0; }

  run mkdir -p "$HOME/Pictures"
  run cp -- "$src" "$dst"
  log "Installed default wallpaper to $dst"
}

enable_services() {
  (( SKIP_SERVICES )) && { log "Skipping service enablement"; return 0; }

  need_cmd systemctl

  local services=(NetworkManager.service bluetooth.service)
  (( ENABLE_LY )) && services+=(ly.service)

  log "Enabling services"
  local service
  for service in "${services[@]}"; do
    if (( DRY_RUN )); then
      log "[dry-run] sudo systemctl enable --now $service"
      continue
    fi
    if systemctl list-unit-files "$service" >/dev/null 2>&1; then
      run_sudo systemctl enable --now "$service"
    else
      warn "Service not found: $service"
    fi
  done
}

set_default_shell() {
  (( SKIP_SHELL )) && { log "Skipping shell change"; return 0; }

  need_cmd zsh
  local zsh_path
  zsh_path="$(command -v zsh)"

  [[ "${SHELL:-}" == "$zsh_path" ]] && { log "Default shell already zsh"; return 0; }

  if (( DRY_RUN )); then
    log "[dry-run] chsh -s $zsh_path $USER"
    return 0
  fi

  if ! grep -qxF "$zsh_path" /etc/shells; then
    echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  fi

  log "Changing default shell to zsh"
  chsh -s "$zsh_path" "$USER"
}

postflight() {
  cat <<EOF

[install] Done.

Next steps:
  1. Log out and log back in.
  2. Start Hyprland from your display manager/TTY.
  3. If you want ly instead of your current display manager, rerun with: ./install.sh --enable-ly

Backups, if any, are in:
  $BACKUP_DIR
EOF
}

main() {
  preflight
  install_packages
  deploy_dotfiles
  deploy_default_wallpaper
  enable_services
  set_default_shell
  postflight
}

main "$@"
