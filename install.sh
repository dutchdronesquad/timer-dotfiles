#!/bin/bash
set -euo pipefail

#----------------------------------------
# PRE-FLIGHT CHECKS
#----------------------------------------
if [ "$EUID" -eq 0 ]; then
  echo "Do not run this script as root. Sudo is used where needed."
  exit 1
fi

# Source shared logging library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logger.sh"

trap 'error "An error occurred. Exiting."' ERR

DOTFILES="$HOME/timer-dotfiles/config"
USER="$(whoami)"

#----------------------------------------
# LINK DOTFILES
#----------------------------------------
log_header "Dotfiles Configuration"
log_info "Symlinking dotfiles"
mkdir -p "$HOME"
ln -sf "$DOTFILES/.gitconfig" "$HOME/.gitconfig"
ln -sf "$DOTFILES/.gitignore" "$HOME/.gitignore"
ln -sf "$DOTFILES/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES/theme.omp.json" "$HOME/.theme.omp.json"

#----------------------------------------
# INTERACTIVE GIT CONFIGURATION
#----------------------------------------
log_header "Git Configuration"
log_info "Configuring Git user.name / user.email"

if ! git config --global user.name &>/dev/null; then
  read -p "Enter your Git user name: " GIT_NAME
  git config --global user.name "$GIT_NAME"
fi

if ! git config --global user.email &>/dev/null; then
  read -p "Enter your Git email address: " GIT_EMAIL
  git config --global user.email "$GIT_EMAIL"
fi

log_success "Git global user.name/email configured"

#----------------------------------------
# UPDATE & BASE PACKAGES
#----------------------------------------
log_header "System Packages"
log_info "Installing apt packages"
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends zsh fzf vim jq unzip

#----------------------------------------
# ZSH SHELL
#----------------------------------------
log_header "Shell Configuration"
if [ "$(basename "$SHELL")" != "zsh" ]; then
  log_info "Switching default shell to Zsh"
  sudo chsh "$USER" -s "$(command -v zsh)"
  SHELL_CHANGED=1
else
  log_success "Zsh is already the default shell"
  SHELL_CHANGED=0
fi

#----------------------------------------
# GH CLI
#----------------------------------------
log_header "GitHub CLI"
if ! command -v gh &>/dev/null; then
  log_info "Installing GitHub CLI"
  LATEST_DEB=$(curl -s https://api.github.com/repos/cli/cli/releases/latest | jq -r '.assets[] | select(.name | endswith("_linux_armv6.deb")).browser_download_url')
  curl -LO "$LATEST_DEB"
  if [ -f ./gh_*.deb ]; then
    sudo dpkg -i ./gh_*.deb
    rm ./gh_*.deb
    log_success "GitHub CLI installed"
  else
    error "GitHub CLI .deb download failed!"
  fi
else
  log_success "GitHub CLI already installed"
fi

#----------------------------------------
# OH MY ZSH + PLUGINS
#----------------------------------------
log_header "Oh My Zsh"
log_info "Installing Oh My Zsh and plugins"
rm -rf "$HOME/.oh-my-zsh"
touch "$HOME/.z"  # Avoid warning on first use
CHSH=no RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Plugins
[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ] || git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ] || git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"

#----------------------------------------
# OH MY POSH
#----------------------------------------
log_header "Oh My Posh"
if ! command -v oh-my-posh &>/dev/null; then
  log_info "Installing Oh My Posh"
  curl -s https://ohmyposh.dev/install.sh | bash -s
  log_success "Oh My Posh installed"
else
  log_success "Oh My Posh already installed"
fi

#----------------------------------------
# PYENV
#----------------------------------------
log_header "Pyenv"
PYENV_ROOT="$HOME/.pyenv"

if command -v pyenv &>/dev/null; then
  log_success "Pyenv is already installed and available"
else
  if [ -d "$PYENV_ROOT" ]; then
    log_warning "Pyenv directory exists, but command not found. Removing possibly broken install..."
    rm -rf "$PYENV_ROOT"
  fi

  log_info "Installing fresh Pyenv"
  curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash

  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
  eval "$(pyenv virtualenv-init -)"

  if command -v pyenv &>/dev/null; then
    log_success "Pyenv installed successfully"
  else
    error "Pyenv installation failed"
  fi
fi

#----------------------------------------
# UV
#----------------------------------------
log_header "UV Python Package Manager"
if ! command -v uv &>/dev/null; then
  log_info "Installing UV"
  curl -LsSf https://astral.sh/uv/install.sh | sh
  log_success "UV installed"
else
  log_success "UV already installed"
fi

#----------------------------------------
# UV SHELL COMPLETION
#----------------------------------------
log_info "Setting up UV shell completion"

if [ -f "$HOME/.zshrc" ] && ! grep -q 'uv generate-shell-completion zsh' "$HOME/.zshrc"; then
  echo 'eval "$(uv generate-shell-completion zsh)"' >> "$HOME/.zshrc"
  log_success "UV shell completion added to .zshrc"
else
  log_step "UV shell completion already configured"
fi

#----------------------------------------
# NVM (NodeJS)
#----------------------------------------
log_header "NVM (Node Version Manager)"
if [ ! -d "$HOME/.nvm" ]; then
  log_info "Installing NVM"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  log_success "NVM installed"
else
  log_success "NVM already installed"
fi

#----------------------------------------
# SYSTEM CLEANUP
#----------------------------------------
log_header "Cleanup"
log_info "Cleaning up apt cache"
sudo apt-get autoremove -y
sudo apt-get clean
log_success "System cleanup complete"

echo ""
log_success "Installation complete!"
if [ "${SHELL_CHANGED:-0}" = "1" ]; then
  log_warning "Log out and log in again to use ZSH as your default shell"
fi
