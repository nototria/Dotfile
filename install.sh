#!/bin/bash

set -e
set -o pipefail 

LOG_FILE="$HOME/install.log"
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
  if [[ -f "requirements.txt" ]]; then
    echo "Installing packages from requirements.txt..."
    while IFS= read -r package; do
      install_package "$package"
  done < "requirements.txt"
  else
    echo "requirements.txt not found. Skipping package installation."
  fi
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

install_tpm() {
    local tpm_dir="$HOME/.tmux/plugins/tpm"

    if [ -d "$tpm_dir" ]; then
        echo "TPM is already installed at $tpm_dir"
    else
        echo "Installing TPM..."
        git clone https://github.com/tmux-plugins/tpm "$tpm_dir" && echo "TPM installed successfully!"
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

cleanup_directory() {
  local dotfile_dir="$HOME/Dotfile"
  echo "Cleaning up existing files in the home directory..."
  for file in "$dotfile_dir"/*; do
    filename=$(basename "$file")
    if [ -e "$HOME/$filename" ]; then
      echo "Removing $HOME/$filename"
      rm -rf "$HOME/$filename"
    fi
  done
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
  backup_zshrc

  echo "Installing Zsh plugins..."
  install_zsh_plugins

  echo "Installing fzf..."
  install_fzf

  echo "Installing tpm..."
  install_tpm

  echo "Installing Nerd Fonts..."
  install_nerd_fonts

  echo "Stowing dotfiles..."
  cleanup_directory "$HOME"
  stow .

  echo "Prompting user to change shell to Zsh..."
  change_shell_to_zsh

  echo "Installation complete! Log saved to $LOG_FILE."
}

main

