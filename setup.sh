#!/bin/sh -e

# Install necessary dependencies for Termux
apt update && apt install -y ncurses-utils curl coreutils git bash-completion tar bat tree fastfetch wget unzip

# Define color codes using tput
RC=$(tput sgr0)
RED=$(tput setaf 1)
YELLOW=$(tput setaf 3)
GREEN=$(tput setaf 2)

LINUXTOOLBOXDIR="$HOME/linuxtoolbox"
PACKAGER="apt"
GITPATH="$HOME"

# Helper functions
print_colored() {
    printf "${1}%s${RC}\n" "$2"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Setup directories
setup_directories() {
    if [ ! -d "$LINUXTOOLBOXDIR" ]; then
        print_colored "$YELLOW" "Creating linuxtoolbox directory: $LINUXTOOLBOXDIR"
        mkdir -p "$LINUXTOOLBOXDIR"
        print_colored "$GREEN" "linuxtoolbox directory created: $LINUXTOOLBOXDIR"
    fi

    if [ -d "$LINUXTOOLBOXDIR/mybash" ]; then rm -rf "$LINUXTOOLBOXDIR/mybash"; fi

    print_colored "$YELLOW" "Cloning mybash repository into: $LINUXTOOLBOXDIR/mybash"
    if git clone https://github.com/ChrisTitusTech/mybash "$LINUXTOOLBOXDIR/mybash"; then
        print_colored "$GREEN" "Successfully cloned mybash repository"
    else
        print_colored "$RED" "Failed to clone mybash repository"
        exit 1
    fi

    cd "$LINUXTOOLBOXDIR/mybash" || exit
}

# Check environment
check_environment() {
    REQUIREMENTS='curl groups'
    for req in $REQUIREMENTS; do
        if ! command_exists "$req"; then
            print_colored "$RED" "To run me, you need: $REQUIREMENTS"
            exit 1
        fi
    done

    print_colored "$GREEN" "All required dependencies are installed!"
}

# Install dependencies (removed trash-cli)
install_dependencies() {
    DEPENDENCIES='bash bash-completion tar bat tree fastfetch wget unzip'

    if ! command_exists nvim; then
        DEPENDENCIES="${DEPENDENCIES} neovim"
    fi

    print_colored "$YELLOW" "Installing dependencies..."
    apt install -yq ${DEPENDENCIES}
}

# Install Starship (Fixed install path)
install_starship() {
    if ! command_exists starship; then
        print_colored "$YELLOW" "Installing Starship prompt..."
        curl -fsSL https://starship.rs/install.sh | sh -s -- --bin-dir "$PREFIX/bin" --yes
        print_colored "$GREEN" "Starship installed successfully!"
    else
        print_colored "$GREEN" "Starship already installed"
    fi
}

# Install FZF
install_fzf() {
    if ! command_exists fzf; then
        print_colored "$YELLOW" "Installing FZF..."
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install
        print_colored "$GREEN" "FZF installed successfully!"
    else
        print_colored "$GREEN" "FZF already installed"
    fi
}

# Install Zoxide
install_zoxide() {
    if ! command_exists zoxide; then
        print_colored "$YELLOW" "Installing Zoxide..."
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
        print_colored "$GREEN" "Zoxide installed successfully!"
    else
        print_colored "$GREEN" "Zoxide already installed"
    fi
}

# Link config files
link_config() {
    BASHRC="$HOME/.bashrc"
    BASH_PROFILE="$HOME/.bash_profile"

    if [ -e "$BASHRC" ]; then
        print_colored "$YELLOW" "Backing up existing .bashrc to .bashrc.bak"
        mv "$BASHRC" "$HOME/.bashrc.bak"
    fi

    print_colored "$YELLOW" "Linking new bash config..."
    ln -svf "$GITPATH/.bashrc" "$HOME/.bashrc"
    ln -svf "$GITPATH/starship.toml" "$HOME/.config/starship.toml"

    # Create .bash_profile if it doesn't exist
    if [ ! -f "$BASH_PROFILE" ]; then
        print_colored "$YELLOW" "Creating .bash_profile..."
        echo "[ -f ~/.bashrc ] && . ~/.bashrc" > "$BASH_PROFILE"
        print_colored "$GREEN" ".bash_profile created and configured to source .bashrc"
    else
        print_colored "$YELLOW" ".bash_profile already exists. Please ensure it sources .bashrc if needed."
    fi
}

# Main execution
setup_directories
check_environment
install_dependencies
install_starship
install_fzf
install_zoxide

if link_config; then
    print_colored "$GREEN" "Done! Restart your shell to see the changes."
else
    print_colored "$RED" "Something went wrong!"
fi

