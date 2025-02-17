#!/bin/bash

set -e
set -o pipefail 

LOG_FILE="install.log"
exec > >(tee -i "$LOG_FILE") 2>&1

echo "Starting installation script at $(date)..."

install_package() {
  local package=$1

  echo "Installing package: $package"
  if [[ "$(uname)" == "Linux" ]]; then
    if command -v pacman &> /dev/null; then
      sudo pacman -S --noconfirm "$package"
    elif command -v apt-get &> /dev/null; then
      sudo apt-get install -y "$package"
    else
      echo "Unsupported Linux distribution. Please install $package manually."
      return 1
    fi
  elif [[ "$(uname)" == "Darwin" ]]; then
    if ! command -v brew &> /dev/null; then
      echo "Homebrew not found. Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install "$package"
  else
    echo "Unsupported OS. Please install $package manually."
    return 1
  fi
}

ensure_dependencies() {
  local dependencies=("stow" "zsh" "git" "wget" "jq" "unzip")
  for dep in "${dependencies[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
      echo "$dep not found. Installing..."
      install_package "$dep"
    else
      echo "$dep is already installed."
    fi
  done
}

backup_zshrc() {
  if [[ -f "$HOME/.zshrc" ]]; then
    echo "Backing up existing .zshrc to .zshrc.bak"
    mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
  fi
}

install_oh_my_zsh() {
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "Installing Oh My Zsh..."
    git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
  else
    echo "Oh My Zsh is already installed."
  fi
}

install_zsh_plugins() {
  local plugin_list="zplugin_requirement.txt"
  if [[ -f "$plugin_list" ]]; then
    echo "Installing Zsh plugins..."
    while IFS= read -r plugin; do
      local plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$(basename "$plugin" .git)"
      if [[ ! -d "$plugin_dir" ]]; then
	echo "Installing $plugin..."
	git clone "$plugin" "$plugin_dir"
      else
	echo "Plugin $plugin already installed."
      fi
    done < "$plugin_list"
  else
    echo "$plugin_list not found. Skipping plugin installation."
  fi
}

install_fzf() {
  if [[ ! -d "$HOME/.fzf" ]]; then
    echo "Installing fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all
  else
    echo "fzf is already installed."
  fi
}

install_nerd_fonts() {
  echo "Installing Nerd Fonts..."
  local fonts=("JetBrainsMono" "Meslo")
  local version
  version=$(curl -s 'https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest' | jq -r '.name')
  local fonts_dir="${HOME}/.local/share/fonts"

  mkdir -p "$fonts_dir"
  for font in "${fonts[@]}"; do
    if ! ls "$fonts_dir" | grep -q "${font}.*\.ttf"; then
      echo "Installing $font..."
      local zip_file="${font}.zip"
      wget "https://github.com/ryanoasis/nerd-fonts/releases/download/${version}/${zip_file}" -O "$zip_file"
      unzip "$zip_file" -d "$fonts_dir"
      rm "$zip_file"
    else
      echo "$font is already installed."
    fi
  done
  fc-cache -fv
}

cleanup_home_directory() {
  local target_dir="$1"
  if [ ! -d "$target_dir" ]; then
    echo "Error: Directory $target_dir does not exist."
    return 1
  fi
  echo "Cleaning up existing files in $target_dir..."
  find "$target_dir" -mindepth 1 -exec rm -rf {} \;
}

change_shell_to_zsh() {
  local current_shell
  current_shell=$(getent passwd "$(whoami)" | cut -d: -f7)

  if [[ "$current_shell" == "$(which zsh)" ]]; then
    echo "Your default shell is already set to Zsh."
    return
  fi

  echo "Your current shell is: $current_shell"
  read -p "Do you want to change your default shell to Zsh? (y/n): " choice
  case "$choice" in
    [Yy]* )
      echo "Changing default shell to Zsh..."
      chsh -s "$(which zsh)" "$(whoami)"
      echo "Default shell changed to Zsh. Please restart your terminal for changes to take effect."
      ;;
    [Nn]* )
      echo "Skipping shell change. You can manually change it later with:"
      echo "  chsh -s $(which zsh) $(whoami)"
      ;;
    * )
      echo "Invalid input. Skipping shell change."
      ;;
  esac
}

main() {
  echo "Ensuring dependencies are installed..."
  ensure_dependencies

  echo "Installing Oh My Zsh..."
  install_oh_my_zsh

  echo "Restoring .zshrc..."
  backup_and_restore_zshrc

  echo "Installing Zsh plugins..."
  install_zsh_plugins

  echo "Installing fzf..."
  install_fzf

  echo "Installing Nerd Fonts..."
  install_nerd_fonts

  if [[ -f "requirements.txt" ]]; then
    echo "Installing packages from requirements.txt..."
    while IFS= read -r package; do
      install_package "$package"
    done < "requirements.txt"
  else
    echo "requirements.txt not found. Skipping package installation."
  fi

  echo "Stowing dotfiles..."
  cleanup_home_directory "$HOME"
  stow .

  echo "Prompting user to change shell to Zsh..."
  change_shell_to_zsh

  echo "Installation complete! Log saved to $LOG_FILE."
}

main

