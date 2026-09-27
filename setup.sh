#!/usr/bin/env bash
set -euo pipefail

# Collors
RESET=$'\e[0m'
GREEN=$'\e[1;32m'
YELLOW=$'\e[1;33m'
RED=$'\e[1;31m'
BLUE=$'\e[1;34m'

# Messages
success() { printf '%s[SUCCESS]%s %s\n' "${GREEN}" "${RESET}" "$1"; }
warning() { printf '%s[WARNING]%s %s\n' "${YELLOW}" "${RESET}" "$1"; }
error() { printf '%s[ERROR]%s %s\n' "${RED}" "${RESET}" "$1"; }
check() { printf '%s[CHECK]%s %s\n' "${BLUE}" "${RESET}" "$1"; }
spacer() { printf -- '-----------------------------------------\n'; }

install_apt_package() {
  local package="$1"
  local binary="${2:-$1}"

  check "Installation of ${package}..."
  if command -v "$binary" >/dev/null 2>&1; then
    success "${package} It is already installed."
    return 0
  fi

  warning "${package} Installing..."
  if $SUDO apt install -y "$package"; then
    success "${package} Installed."
  else
    error "Installation failed ${package}."
    exit 1
  fi
}

# Update
spacer
check "OS ..."

if [[ ! -f /etc/os-release ]]; then
  error "Could not locate /etc/os-release. Unable to identify the system."
  exit 1
fi

source /etc/os-release

if [[ "${ID:-}" != "pop" ]]; then
  error "This script is intended only for Pop!_OS. System detected.: ${PRETTY_NAME:-unknown}"
  exit 1
fi

success "System identified: ${PRETTY_NAME}"

if [[ "$EUID" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

check "Updating package list..."
if $SUDO apt update; then
  success "Updated package listc."
else
  error "Failed to execute 'apt update'."
  exit 1
fi

UPGRADABLE=$(apt list --upgradable 2>/dev/null | grep -c upgradable || true)

if [[ "$UPGRADABLE" -eq 0 ]]; then
  warning "No packages to update. The system is already up to date."
fi

success "Found ${UPGRADABLE} package(s) to update."

warning "Starting package update"
if $SUDO apt upgrade -y; then
  success "System updated!"
else
  error "Failed to execute 'apt upgrade'."
  exit 1
fi

spacer

install_apt_package "zsh"
install_apt_package "tmux"
install_apt_package "git"
install_apt_package "alacritty"
install_apt_package "shellcheck"
install_apt_package "shfmt"

check "Installation Oh My Zsh..."
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  success "Oh My Zsh It is already installed."
else
  warning "Installing..."
  if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
    success "Oh My Zsh Installed."
  else
    error "Failed to install Oh My Zsh."
    exit 1
  fi
fi

check "Oh My Posh installation..."
if command -v oh-my-posh >/dev/null 2>&1; then
  success "Oh My Posh is already installed."
else
  warning "Installing..."
  if curl -s https://ohmyposh.dev/install.sh | bash -s; then
    success "Oh My Posh installed."
  else
    error "Failed to install Oh My Posh."
    exit 1
  fi
fi

spacer

check "TPM (Tmux Plugin Manager) installation..."
if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
  success "TPM is already installed."
else
  warning "Installing TPM..."
  if git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"; then
    success "TPM installed."
  else
    error "Failed to install TPM."
    exit 1
  fi
fi

spacer

check "Zed installation..."
if command -v zed >/dev/null 2>&1; then
  success "Zed is already installed."
else
  warning "Installing..."
  if curl -f https://zed.dev/install.sh | sh; then
    success "Zed installed."
  else
    error "Failed to install Zed"
    exit 1
  fi
fi

spacer

#sudo chsh -s "$(which zsh)" "$USER"

#fc-cache -fv
