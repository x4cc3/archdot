#!/usr/bin/env bash
set -Eeuo pipefail

log()  { printf '[install] %s\n' "$*"; }
warn() { printf '[install][warn] %s\n' "$*" >&2; }
die()  { printf '[install][error] %s\n' "$*" >&2; exit 1; }

DRY_RUN=0
SKIP_PACKAGES=0
SKIP_AUR=0
SKIP_SERVICES=0
SKIP_SHELL=0
ENABLE_LY=0
REPLACE_CONFLICTS=0

usage() {
  cat <<'USAGE'
Usage: ./install.sh [options]

Options:
  --dry-run            Print commands without executing
  --skip-packages      Skip pacman/yay package installation
  --skip-aur           Skip AUR package installation
  --skip-services      Skip enabling system services
  --skip-shell         Skip changing default shell to zsh
  --enable-ly          Install/enable ly display manager service
  --replace-conflicts  Replace known conflicting packages with this setup's choices
  -h, --help           Show this help

Examples:
  ./install.sh --dry-run
  ./install.sh --skip-packages
  ./install.sh --replace-conflicts
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --skip-packages) SKIP_PACKAGES=1 ;;
    --skip-aur) SKIP_AUR=1 ;;
    --skip-services) SKIP_SERVICES=1 ;;
    --skip-shell) SKIP_SHELL=1 ;;
    --enable-ly) ENABLE_LY=1 ;;
    --replace-conflicts) REPLACE_CONFLICTS=1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
  shift
done

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

need_cmd() {
  have_cmd "$1" || die "Missing required command: $1"
}

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

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$HOME/.config/dotfiles-backups/$TIMESTAMP"
USER_NAME="${USER:-$(id -un)}"

needs_sudo() {
  (( DRY_RUN )) && return 1
  (( ! SKIP_PACKAGES || ! SKIP_SERVICES || ! SKIP_SHELL ))
}

preflight() {
  [[ ${EUID:-$(id -u)} -ne 0 ]] || die "Run this as your normal user, not root."

  need_cmd bash
  need_cmd realpath
  need_cmd awk

  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    if [[ "${ID:-}" != "arch" && "${ID_LIKE:-}" != *arch* ]]; then
      warn "This installer is meant for Arch/Arch-based systems. Detected: ${ID:-unknown}"
    fi
  else
    warn "Cannot read /etc/os-release; skipping distro check."
  fi

  if needs_sudo; then
    need_cmd sudo
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

  run mkdir -p "$(dirname -- "$dst")"
  backup_target_if_needed "$dst" "$src"

  # Create a relative symlink so the dotfiles work regardless of where
  # the repo is cloned or what the user's home directory is.
  local rel_src
  rel_src="$(realpath --relative-to="$(dirname -- "$dst")" -- "$src")"
  run ln -sfn -- "$rel_src" "$dst"
}

pacman_pkg_available() {
  pacman -Si "$1" >/dev/null 2>&1
}

aur_pkg_available() {
  yay -Si "$1" >/dev/null 2>&1
}

remove_if_installed() {
  local pkg="$1"
  if pacman -Qi "$pkg" >/dev/null 2>&1; then
    log "Removing conflicting package: $pkg"
    run_sudo pacman -Rns --noconfirm "$pkg"
  fi
}

handle_known_conflicts() {
  local conflicts=()
  local pkg

  # pipewire-pulse is the intended audio stack for this Waybar/Hyprland config.
  for pkg in pulseaudio pulseaudio-bluetooth pulseaudio-jack; do
    pacman -Qi "$pkg" >/dev/null 2>&1 && conflicts+=("$pkg")
  done

  if (( ${#conflicts[@]} == 0 )); then
    return 0
  fi

  if (( REPLACE_CONFLICTS )); then
    for pkg in "${conflicts[@]}"; do
      remove_if_installed "$pkg"
    done
    return 0
  fi

  warn "Known conflicting packages are installed: ${conflicts[*]}"
  warn "Not removing them automatically. Re-run with --replace-conflicts to switch to this setup's PipeWire stack."
  return 1
}

install_yay_if_missing() {
  (( SKIP_AUR )) && { log "Skipping AUR helper installation"; return 1; }
  have_cmd yay && { log "yay already installed"; return 0; }

  log "Installing yay-bin from AUR"
  run_sudo pacman -S --needed --noconfirm git base-devel

  if (( DRY_RUN )); then
    log "[dry-run] Would clone yay-bin and run makepkg -si"
    return 0
  fi

  need_cmd git
  need_cmd makepkg

  local tmp
  tmp="$(mktemp -d)"
  if ! git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"; then
    rm -rf -- "$tmp"
    return 1
  fi
  if ! (cd "$tmp/yay-bin" && makepkg -si --noconfirm); then
    rm -rf -- "$tmp"
    return 1
  fi
  rm -rf -- "$tmp"
}

install_packages() {
  (( SKIP_PACKAGES )) && { log "Skipping package installation"; return 0; }

  need_cmd pacman

  handle_known_conflicts || return 1

  local pacman_pkgs=(
    git base-devel jq pacman-contrib
    zsh fzf zoxide fastfetch starship neovim reflector maven unzip unrar 7zip
    go rustup npm rbenv python python-pipx python2 ruff
    hyprland hypridle hyprlock
    waybar rofi wl-clipboard cliphist dunst
    polkit-gnome gnome-keyring xdg-desktop-portal-hyprland xdg-desktop-portal xdg-desktop-portal-gtk
    qt5-wayland qt6-wayland qt5ct qt6ct kvantum kvantum-qt5
    gnome-settings-daemon dconf glib2 xorg-xrdb
    pipewire pipewire-alsa pipewire-pulse wireplumber pavucontrol playerctl
    networkmanager network-manager-applet blueman bluez bluez-utils
    ghostty firefox thunar spotify-launcher
    ttf-jetbrains-mono-nerd ttf-fira-code otf-font-awesome noto-fonts noto-fonts-emoji papirus-icon-theme
    swappy grim slurp imagemagick qalculate-gtk xclip brightnessctl libnotify
  )

  # The keybind uses the `code` command. visual-studio-code-bin also provides it,
  # so do not force-remove a user's AUR VS Code package.
  if pacman -Qi visual-studio-code-bin >/dev/null 2>&1; then
    warn "visual-studio-code-bin already installed; skipping official code package."
  else
    pacman_pkgs+=(code)
  fi

  (( ENABLE_LY )) && pacman_pkgs+=(ly)

  local aur_pkgs=(
    zen-browser-bin
    webcord
    caffeine-ng
    wlogout
    awww
    graphite-gtk-theme
    arc-gtk-theme
    bibata-cursor-theme-bin
  )

  local avail_pacman_pkgs=()
  local p
  for p in "${pacman_pkgs[@]}"; do
    if pacman_pkg_available "$p"; then
      avail_pacman_pkgs+=("$p")
    else
      warn "Skipping unknown pacman package: $p"
    fi
  done

  if (( ${#avail_pacman_pkgs[@]} > 0 )); then
    log "Installing/updating official packages"
    run_sudo pacman -Syu --needed --noconfirm "${avail_pacman_pkgs[@]}"
  else
    warn "No official packages to install"
  fi

  (( SKIP_AUR )) && { log "Skipping AUR package installation"; return 0; }

  if ! install_yay_if_missing; then
    warn "Skipping AUR package install (yay installation failed or unavailable)."
    return 0
  fi

  local avail_aur_pkgs=()
  for p in "${aur_pkgs[@]}"; do
    if aur_pkg_available "$p"; then
      avail_aur_pkgs+=("$p")
    else
      warn "Skipping unknown AUR package: $p"
    fi
  done

  if (( ${#avail_aur_pkgs[@]} > 0 )); then
    log "Installing AUR packages"
    run yay -S --needed --noconfirm "${avail_aur_pkgs[@]}" || warn "Some AUR packages failed to install"
  else
    warn "No AUR packages to install"
  fi
}

deploy_dotfiles() {
  local config_dirs=(
    hypr hyprfloat waybar rofi dunst wlogout swappy scripts ghostty fastfetch gtk-4.0 zed xsettingsd
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
  link_path "$DOTFILES_DIR/gtkrc" "$HOME/.config/gtkrc"
  link_path "$DOTFILES_DIR/gtkrc-2.0" "$HOME/.config/gtkrc-2.0"
  link_path "$DOTFILES_DIR/gtkrc-2.0" "$HOME/.gtkrc-2.0"

  deploy_gtk3_config

  check_link "$DOTFILES_DIR/hypr" "$HOME/.config/hypr"
  check_link "$DOTFILES_DIR/waybar" "$HOME/.config/waybar"
  check_link "$DOTFILES_DIR/rofi" "$HOME/.config/rofi"

  local script_dir
  for script_dir in "$DOTFILES_DIR/scripts" "$DOTFILES_DIR/hypr/scripts" "$DOTFILES_DIR/waybar/scripts"; do
    [[ -d "$script_dir" ]] && run find "$script_dir" -type f -name '*.sh' -exec chmod +x {} +
  done
}

deploy_gtk3_config() {
  local src="$DOTFILES_DIR/gtk-3.0"
  local dst="$HOME/.config/gtk-3.0"

  [[ -d "$src" ]] || { warn "Missing GTK 3 source: $src"; return 0; }

  if (( DRY_RUN )); then
    log "[dry-run] Would copy GTK 3 settings and normalize bookmarks for user home"
    log "[dry-run] mkdir -p $dst"
    log "[dry-run] cp -a $src/. $dst/"
    if [[ -f "$src/bookmarks" ]]; then
      log "[dry-run] render bookmarks from $src/bookmarks to $dst/bookmarks with home=$HOME"
    fi
    return 0
  fi

  if [[ -e "$dst" && ! -d "$dst" || -L "$dst" ]]; then
    backup_target_if_needed "$dst" "$src"
  fi

  run mkdir -p "$dst"
  run cp -a "$src/." "$dst/"

  if [[ -f "$src/bookmarks" ]]; then
    local tmp
    tmp="${dst}/.bookmarks.tmp"
    awk -v home="$HOME" '{gsub(/^file:\/\/\/home\/[^\/]+/, "file://" home, $0); print}' "$src/bookmarks" > "$tmp"
    run mv -f "$tmp" "$dst/bookmarks"
  fi

  log "Configured $dst"
}

deploy_default_wallpaper() {
  local dst="$HOME/Pictures/default.png"
  local src="$DOTFILES_DIR/wallpapers/1920x1080-dark-linux.png"

  [[ -f "$src" ]] || { warn "Default wallpaper not found: $src"; return 0; }

  if [[ -f "$dst" ]]; then
    log "Default wallpaper already exists"
  else
    run mkdir -p "$HOME/Pictures"
    run cp -- "$src" "$dst"
    if (( DRY_RUN )); then
      log "[dry-run] Would install default wallpaper to $dst"
    else
      log "Installed default wallpaper to $dst"
    fi
  fi

  ensure_hyprlock_wallpaper "$dst"
}

ensure_hyprlock_wallpaper() {
  local fallback_wallpaper="$1"
  local cache_wallpaper="$HOME/.cache/current_wallpaper"
  local lock_wallpaper="$HOME/.cache/hyprlock_wallpaper"
  local selected_wallpaper=""

  if [[ -f "$cache_wallpaper" ]]; then
    selected_wallpaper="$(<"$cache_wallpaper")"
  fi

  if [[ -z "$selected_wallpaper" || ! -f "$selected_wallpaper" ]]; then
    selected_wallpaper="$fallback_wallpaper"
  fi

  [[ -f "$selected_wallpaper" ]] || { warn "No wallpaper available for hyprlock"; return 0; }

  run mkdir -p "$(dirname -- "$lock_wallpaper")"
  run ln -sfn -- "$selected_wallpaper" "$lock_wallpaper"
}

check_link() {
  local src="$1"
  local dst="$2"

  if [[ -L "$dst" ]] && [[ "$(readlink -f -- "$dst")" == "$(realpath -- "$src")" ]]; then
    log "Linked $dst -> $src"
  else
    warn "$dst is not linked to $src"
  fi
}

enable_services() {
  (( SKIP_SERVICES )) && { log "Skipping service enablement"; return 0; }

  if ! have_cmd systemctl; then
    warn "systemctl not found; skipping service enablement"
    return 0
  fi

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

  if ! have_cmd zsh; then
    warn "zsh not installed; skipping shell change"
    return 0
  fi

  local zsh_path
  zsh_path="$(command -v zsh)"

  [[ "${SHELL:-}" == "$zsh_path" ]] && { log "Default shell already zsh"; return 0; }

  if (( DRY_RUN )); then
    log "[dry-run] chsh -s $zsh_path $USER_NAME"
    return 0
  fi

  if ! grep -qxF "$zsh_path" /etc/shells; then
    echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  fi

  log "Changing default shell to zsh"
  chsh -s "$zsh_path" "$USER_NAME"
}

validate_install() {
  log "Running best-effort validation"

  local hypr_config="$HOME/.config/hypr/hyprland.lua"
  local waybar_config="$HOME/.config/waybar/config"
  local ghostty_config="$HOME/.config/ghostty/config"

  if (( DRY_RUN )); then
    hypr_config="$DOTFILES_DIR/hypr/hyprland.lua"
    waybar_config="$DOTFILES_DIR/waybar/config"
    ghostty_config="$DOTFILES_DIR/ghostty/config"
  fi

  if have_cmd hyprland && [[ -f "$hypr_config" ]]; then
    hyprland --verify-config --config "$hypr_config" >/tmp/dotfiles-hyprland-verify.log 2>&1 \
      && log "Hyprland config validation passed" \
      || warn "Hyprland config validation failed; see /tmp/dotfiles-hyprland-verify.log"
  fi

  if have_cmd jq && [[ -f "$waybar_config" ]]; then
    jq empty "$waybar_config" >/dev/null \
      && log "Waybar JSON validation passed" \
      || warn "Waybar JSON validation failed"
  fi

  if have_cmd ghostty && [[ -f "$ghostty_config" ]]; then
    ghostty +validate-config --config-file="$ghostty_config" >/dev/null 2>&1 \
      && log "Ghostty config validation passed" \
      || warn "Ghostty config validation failed"
  fi
}

postflight() {
  cat <<EOF

[install] Done.

Next steps:
  1. Log out and log back in.
  2. Start Hyprland from your display manager/TTY.
  3. If you use a different monitor layout, edit ~/.config/hypr/lua/monitor.lua.
  4. If you want ly instead of your current display manager, rerun with: ./install.sh --enable-ly

Backups, if any, are in:
  $BACKUP_DIR
EOF
}

main() {
  preflight
  install_packages || warn "Package installation had errors; continuing with configuration deployment."
  deploy_dotfiles
  deploy_default_wallpaper
  enable_services
  set_default_shell
  validate_install
  postflight
}

main "$@"
