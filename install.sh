#!/bin/bash

# Function to install a package based on the OS
install_package() {
  package=$1
  if [ "$(uname)" == "Linux" ]; then
    if command -v pacman &> /dev/null; then
      # Arch-based systems
      sudo pacman -S --noconfirm "$package"
    elif command -v apt-get &> /dev/null; then
      # Debian/Ubuntu-based systems
      sudo apt-get install -y "$package"
    else
      echo "Unsupported Linux distribution. Please install $package manually."
      exit 1
    fi
  elif [ "$(uname)" == "Darwin" ]; then
    # macOS
    if ! command -v brew &> /dev/null; then
      echo "Homebrew not found. Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install "$package"
  else
    echo "Unsupported OS. Please install $package manually."
    exit 1
  fi
}

# Check if GNU Stow is installed
if ! command -v stow &> /dev/null
then
  echo "GNU Stow not found. Installing..."
  install_package "stow"
else
  echo "GNU Stow is already installed."
fi

# Install Zsh if not already installed
if ! command -v zsh &> /dev/null
then
  echo "Zsh not found. Installing Zsh..."
  install_package "zsh"
else
  echo "Zsh is already installed."
fi

# Backup existing .zshrc file if it exists
if [ -f "$HOME/.zshrc" ]; then
  echo "Backing up existing .zshrc to .zshrc.bak"
  mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
fi

# Install Oh My Zsh if not already installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."
  git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
else
  echo "Oh My Zsh is already installed."
fi

# Restore custom .zshrc from dotfiles after Oh My Zsh installation
if [ -f "$HOME/.zshrc.bak" ]; then
  echo "Restoring custom .zshrc"
  rm -f "$HOME/.zshrc"  # Remove the default .zshrc created by Oh My Zsh
  mv "$HOME/.zshrc.bak" "$HOME/.zshrc"
fi

# Install plugins from zplugin_requirement.txt
if [ -f "zplugin_requirement.txt" ]; then
  echo "Installing Zsh plugins..."

  while IFS= read -r plugin
  do
    plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$(basename "$plugin" .git)"
    if [ ! -d "$plugin_dir" ]; then
      echo "Installing $plugin..."
      git clone "$plugin" "$plugin_dir"
    else
      echo "Zsh plugin $plugin already installed."
    fi
  done < "zplugin_requirement.txt"
else
  echo "zplugin_requirement.txt not found, skipping Zsh plugin installation."
fi

# Install fzf after all Zsh plugins are installed
if [ ! -d "$HOME/.fzf" ]; then
  echo "Installing fzf..."
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install
else
  echo "fzf is already installed."
fi

# Check if requirements.txt exists
if [ -f "requirements.txt" ]; then
  echo "Installing packages from requirements.txt..."

    # Loop through each line in requirements.txt and install the package
    while IFS= read -r package
    do
      echo "Installing $package..."
      install_package "$package"
    done < "requirements.txt"
  else
    echo "requirements.txt not found, skipping package installation."
fi

# Function to delete existing files/symlinks in the home directory
cleanup_home_directory() {
  for file in "$1"/*; do
    if [ -d "$file" ]; then
      # Recursively go into directories
      cleanup_home_directory "$file"
    elif [ -f "$file" ]; then
      # Get the relative path to the home directory (or other target dir)
      target="$HOME/$(basename "$file")"

	    # Check if the file or symlink already exists in the target directory
	    if [ -e "$target" ] || [ -L "$target" ]; then
	      echo "Removing existing file or symlink: $target"
	      rm -rf "$target"
	    fi
    fi
  done
}

# Clean up existing files in the home directory
echo "Cleaning up existing files in the home directory..."
cleanup_home_directory "$(pwd)"

# Stow all individual files in the current directory
echo "Stowing files."
stow .

# install Nerd font
echo "installing Nerd fonts."
declare -a fonts=(
JetBrainsMono
Meslo
)
version=$(curl -s 'https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest' | jq -r '.name')
fonts_dir="${HOME}/.local/share/fonts"
if [[ ! -d "$fonts_dir" ]]; then
  mkdir -p "$fonts_dir"
fi
for font in "${fonts[@]}"; do
  font_file="${fonts_dir}/${font}.ttf"
  if ls "$fonts_dir" | grep -q "${font}.*\.ttf"; then
    echo "$font already installed."
  else
    zip_file="${font}.zip"
    download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${version}/${zip_file}"
    echo "Downloading $download_url"
    wget "$download_url"
    unzip "$zip_file" -d "$fonts_dir"
    rm "$zip_file"
  fi
done
find "$fonts_dir" -name 'Windows Compatible' -delete
fc-cache -fv

# change shell to zsh
echo "Changing default shell to zsh."
chsh -s $(which zsh) $(whoami)

echo "Installation complete."

