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

# Install Oh My Zsh if not already installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "Oh My Zsh is already installed."
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
els
    echo "zplugin_requirement.txt not found, skipping Zsh plugin installation."
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

# Function to delete existing files/symlinks and stow individual files
stow_files() {
    for file in "$1"/*; do
        if [ -d "$file" ]; then
            # Recursively go into directories
            stow_files "$file"
        elif [ -f "$file" ]; then
            # Get the relative path to the home directory (or other target dir)
            target="$HOME/$(basename "$file")"

            # Check if the file or symlink already exists in the target directory
            if [ -e "$target" ] || [ -L "$target" ]; then
                echo "Removing existing file or symlink: $target"
                rm -rf "$target"
            fi

            # Stow each individual file
            echo "Stowing file: $file"
            stow "$file"
        fi
    done
}

# Stow all individual files in the current directory
echo "Stowing individual files..."
stow_files "$(pwd)"

echo "Installation complete. Make sure to restart your shell or set Zsh as the default using: chsh -s $(which zsh)"
