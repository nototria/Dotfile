#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${HOME}/install.log"
exec > >(tee -i "$LOG_FILE") 2>&1

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$SCRIPT_DIR}"

OS="$(uname -s)"
ARCH="$(uname -m)"

msg() { printf '%s\n' "$*"; }
die() { msg "ERROR: $*"; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

is_linux() { [[ "$OS" == "Linux" ]]; }
is_macos() { [[ "$OS" == "Darwin" ]]; }

ensure_sudo() {
  if is_linux; then
    if ! have sudo; then die "sudo not found"; fi
  fi
}

apt_update_once() {
  # avoid repeating update for every package
  if [[ "${_APT_UPDATED:-0}" == "1" ]]; then return; fi
  sudo apt-get update -y
  _APT_UPDATED=1
}

install_package() {
  local pkg="$1"
  msg "Installing package: $pkg"

  if is_linux; then
    if have pacman; then
      sudo pacman -S --noconfirm --needed "$pkg"
    elif have apt-get; then
      apt_update_once
      sudo apt-get install -y "$pkg"
    else
      die "Unsupported Linux distro. Install '$pkg' manually."
    fi
  elif is_macos; then
    if ! have brew; then
      msg "Homebrew not found. Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      # shellenv for current run
      if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
      fi
    fi
    brew install "$pkg" || true
  else
    die "Unsupported OS: $OS"
  fi
}

ensure_dependencies_file() {
  local req="${DOTFILES_DIR}/requirements.txt"
  if [[ -f "$req" ]]; then
    msg "Installing packages from requirements.txt..."
    while IFS= read -r pkg; do
      [[ -z "$pkg" ]] && continue
      [[ "$pkg" =~ ^# ]] && continue
      install_package "$pkg"
    done < "$req"
  else
    msg "requirements.txt not found. Skipping."
  fi
}

backup_file_once() {
  local f="$1"
  if [[ -f "$f" && ! -f "${f}.bak" ]]; then
    msg "Backing up $f -> ${f}.bak"
    cp -a "$f" "${f}.bak"
  fi
}

install_oh_my_zsh() {
  if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
    msg "Installing Oh My Zsh..."
    git clone https://github.com/ohmyzsh/ohmyzsh.git "${HOME}/.oh-my-zsh"
  else
    msg "Oh My Zsh already installed."
  fi
}

install_zsh_plugins() {
  local plugin_list="${DOTFILES_DIR}/zplugin_requirement.txt"
  if [[ -f "$plugin_list" ]]; then
    msg "Installing Zsh plugins..."
    while IFS= read -r plugin; do
      [[ -z "$plugin" ]] && continue
      [[ "$plugin" =~ ^# ]] && continue
      local name
      name="$(basename "$plugin" .git)"
      local plugin_dir="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins/${name}"
      if [[ ! -d "$plugin_dir" ]]; then
        msg "Installing $plugin..."
        git clone "$plugin" "$plugin_dir"
      else
        msg "Plugin $name already installed."
      fi
    done < "$plugin_list"
  else
    msg "zplugin_requirement.txt not found. Skipping."
  fi
}

install_fzf() {
  if [[ ! -d "${HOME}/.fzf" ]]; then
    msg "Installing fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git "${HOME}/.fzf"
    "${HOME}/.fzf/install" --all
  else
    msg "fzf already installed."
  fi
}

install_tpm() {
  local tpm_dir="${HOME}/.tmux/plugins/tpm"
  if [[ -d "$tpm_dir" ]]; then
    msg "TPM already installed at $tpm_dir"
  else
    msg "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
  fi
}

ensure_local_bin_on_path() {
  mkdir -p "${HOME}/.local/bin"
  # add to zshrc if missing
  local zshrc="${HOME}/.zshrc"
  backup_file_once "$zshrc"
  if [[ -f "$zshrc" ]]; then
    if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$zshrc"; then
      printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$zshrc"
    fi
  else
    printf 'export PATH="$HOME/.local/bin:$PATH"\n' > "$zshrc"
  fi
  export PATH="${HOME}/.local/bin:${PATH}"
}

install_neovim() {
  msg "Installing Neovim..."

  if is_linux; then
    ensure_sudo
    ensure_local_bin_on_path

    # AppImage prerequisites (Ubuntu typically needs libfuse2; fontconfig for fc-cache)
    if have apt-get; then
      install_package "curl"
      install_package "ca-certificates"
      install_package "libfuse2" || true
    fi

    local asset=""
    case "$ARCH" in
      x86_64|amd64) asset="nvim-linux-x86_64.appimage" ;;
      aarch64|arm64) asset="nvim-linux-arm64.appimage" ;;
      *)
        die "Unsupported Linux arch for AppImage: $ARCH"
        ;;
    esac

    local url="https://github.com/neovim/neovim/releases/latest/download/${asset}"
    local tmp
    tmp="$(mktemp -d)"
    local app="${tmp}/${asset}"

    msg "Downloading ${asset} ..."
    curl -fL --retry 3 --retry-delay 1 -o "$app" "$url"

    # sanity check: AppImage should be big and executable
    local sz
    sz="$(wc -c <"$app" | tr -d ' ')"
    if [[ "$sz" -lt 1000000 ]]; then
      die "Downloaded file too small (${sz} bytes). Check network / GitHub access."
    fi

    chmod +x "$app"

    # If FUSE is missing, fall back to extract mode
    if "$app" --version >/dev/null 2>&1; then
      msg "AppImage runs. Installing to ~/.local/bin/nvim"
      mv -f "$app" "${HOME}/.local/bin/nvim"
      chmod +x "${HOME}/.local/bin/nvim"
    else
      msg "AppImage failed to run (likely FUSE). Using --appimage-extract fallback..."
      (cd "$tmp" && "./${asset}" --appimage-extract >/dev/null)
      rm -f "$app"

      local dest="${HOME}/.local/opt/nvim-appimage"
      rm -rf "$dest"
      mv "${tmp}/squashfs-root" "$dest"
      ln -sf "${dest}/AppRun" "${HOME}/.local/bin/nvim"
    fi

    rm -rf "$tmp"
    msg "Neovim installed: $(command -v nvim)"
    nvim --version | head -n 2 || true

  elif is_macos; then
    # AppImage doesn't apply on macOS; use official Homebrew path.
    # Neovim docs list macOS install methods under Homebrew. :contentReference[oaicite:3]{index=3}
    install_package "neovim"
    msg "Neovim installed: $(command -v nvim)"
    nvim --version | head -n 2 || true

  else
    die "Unsupported OS: $OS"
  fi
}

install_nerd_fonts() {
  msg "Installing Nerd Fonts..."

  if is_macos; then
    # simplest cross-platform path: brew cask fonts (requires tapping fonts)
    install_package "fontconfig" || true
    if have brew; then
      brew tap homebrew/cask-fonts >/dev/null 2>&1 || true
      brew install --cask font-jetbrains-mono-nerd-font || true
      brew install --cask font-meslo-lg-nerd-font || true
    else
      msg "brew not available; skipping fonts on macOS."
    fi
    return
  fi

  # Linux: download from Nerd Fonts GitHub release
  install_package "jq" || true
  install_package "unzip" || true
  install_package "wget" || true
  install_package "fontconfig" || true

  local fonts=("JetBrainsMono" "Meslo")
  local tag
  tag="$(curl -fsSL 'https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest' | jq -r '.tag_name')"
  [[ -z "$tag" || "$tag" == "null" ]] && die "Failed to get Nerd Fonts latest tag"

  local fonts_dir="${HOME}/.local/share/fonts"
  mkdir -p "$fonts_dir"

  for font in "${fonts[@]}"; do
    if ls "$fonts_dir" | grep -qi "${font}.*\.ttf"; then
      msg "$font already present."
      continue
    fi
    msg "Installing $font ($tag)..."
    local zip="${font}.zip"
    wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/${tag}/${zip}" -O "$zip"
    unzip -o -q "$zip" -d "$fonts_dir"
    rm -f "$zip"
  done

  if have fc-cache; then
    fc-cache -fv
  else
    msg "fc-cache not found; skipping font cache refresh."
  fi
}

stow_dotfiles() {
  install_package "stow" || true

  msg "Stowing dotfiles from: $DOTFILES_DIR"
  cd "$DOTFILES_DIR"

  # Stow each top-level directory as a package (safer than `stow .`)
  # skips .git and hidden dirs
  local pkgs=()
  while IFS= read -r d; do
    pkgs+=("$d")
  done < <(find . -maxdepth 1 -mindepth 1 -type d -printf '%f\n' | grep -vE '^\.' || true)

  if [[ "${#pkgs[@]}" -eq 0 ]]; then
    msg "No stow packages found in $DOTFILES_DIR (expected directories like nvim/, zsh/, tmux/). Skipping stow."
    return
  fi

  # Restow: updates symlinks without deleting your $HOME files.
  stow -t "$HOME" -R "${pkgs[@]}"
}

change_shell_to_zsh() {
  # keep it non-interactive by default; allow opt-in via CHANGE_SHELL=1
  if [[ "${CHANGE_SHELL:-0}" != "1" ]]; then
    msg "Skipping chsh (set CHANGE_SHELL=1 to enable)."
    return
  fi

  if ! have zsh; then
    install_package "zsh"
  fi

  if is_linux; then
    local current_shell
    current_shell="$(getent passwd "$(whoami)" | cut -d: -f7 || true)"
    if [[ "$current_shell" == "$(command -v zsh)" ]]; then
      msg "Default shell already zsh."
      return
    fi
  fi

  msg "Changing default shell to zsh..."
  chsh -s "$(command -v zsh)" "$(whoami)" || true
  msg "Done. Restart terminal to take effect."
}

main() {
  msg "Starting installation script at $(date)..."
  msg "OS=$OS ARCH=$ARCH DOTFILES_DIR=$DOTFILES_DIR"

  ensure_dependencies_file

  install_neovim

  install_oh_my_zsh
  backup_file_once "${HOME}/.zshrc"
  install_zsh_plugins

  install_fzf
  install_tpm

  install_nerd_fonts

  stow_dotfiles

  change_shell_to_zsh

  msg "Installation complete! Log saved to $LOG_FILE."
}

main "$@"

