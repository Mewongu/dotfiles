#!/usr/bin/env bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

FORCE=false
CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments
while getopts "fh" opt; do
  case $opt in
    f) FORCE=true ;;
    h)
      echo "Usage: install.sh [-f] [-h]"
      echo "  -f  Force install without prompts"
      echo "  -h  Show this help message"
      exit 0
      ;;
    *) exit 1 ;;
  esac
done

# Helper functions
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

confirm() {
  if $FORCE; then
    return 0
  fi
  read -r -p "$1 [y/N] " response
  case "$response" in
    [yY][eE][sS]|[yY]) return 0 ;;
    *) return 1 ;;
  esac
}

# Detect OS and package manager
detect_os() {
  case "$(uname -s)" in
    Darwin) OS="macos" ;;
    Linux)
      if [ -f /etc/arch-release ]; then
        OS="arch"
      elif [ -f /etc/debian_version ]; then
        OS="debian"
      elif [ -f /etc/fedora-release ]; then
        OS="fedora"
      else
        OS="linux"
      fi
      ;;
    *) OS="unknown" ;;
  esac
  echo "$OS"
}

get_package_manager() {
  local os="$1"
  case "$os" in
    macos) echo "brew" ;;
    arch) echo "pacman" ;;
    debian) echo "apt" ;;
    fedora) echo "dnf" ;;
    *) echo "unknown" ;;
  esac
}

# Package installation
install_package() {
  local pkg="$1"
  local pm="$2"

  case "$pm" in
    brew) brew install "$pkg" ;;
    pacman) sudo pacman -S --noconfirm "$pkg" ;;
    apt) sudo apt install -y "$pkg" ;;
    dnf) sudo dnf install -y "$pkg" ;;
    *) error "Unknown package manager"; return 1 ;;
  esac
}

# Check if command exists
has_cmd() {
  command -v "$1" &>/dev/null
}

# Install fonts
install_fonts() {
  local os="$1"
  local pm="$2"

  info "Installing JetBrains Mono Nerd Font..."
  case "$os" in
    macos)
      if ! brew list --cask font-jetbrains-mono-nerd-font &>/dev/null; then
        brew install --cask font-jetbrains-mono-nerd-font
      else
        success "JetBrains Mono Nerd Font already installed"
      fi
      ;;
    arch)
      install_package "ttf-jetbrains-mono-nerd" "$pm"
      ;;
    debian|fedora)
      # Manual installation for Debian/Fedora
      local font_dir="$HOME/.local/share/fonts"
      mkdir -p "$font_dir"
      if [ ! -f "$font_dir/JetBrainsMonoNerdFont-Regular.ttf" ]; then
        local tmp_dir=$(mktemp -d)
        curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip -o "$tmp_dir/JetBrainsMono.zip"
        unzip -q "$tmp_dir/JetBrainsMono.zip" -d "$font_dir"
        fc-cache -fv
        rm -rf "$tmp_dir"
        success "JetBrains Mono Nerd Font installed"
      else
        success "JetBrains Mono Nerd Font already installed"
      fi
      ;;
  esac
}

# Create symlink with backup
create_symlink() {
  local src="$1"
  local dest="$2"

  if [ -L "$dest" ]; then
    local current_target=$(readlink "$dest")
    if [ "$current_target" = "$src" ]; then
      success "Symlink already exists: $dest -> $src"
      return 0
    else
      warn "Symlink exists but points elsewhere: $dest -> $current_target"
      if confirm "Replace symlink?"; then
        rm "$dest"
      else
        return 0
      fi
    fi
  elif [ -e "$dest" ]; then
    warn "File exists at $dest"
    if confirm "Backup and replace?"; then
      mv "$dest" "${dest}.backup.$(date +%Y%m%d%H%M%S)"
      info "Backed up to ${dest}.backup.*"
    else
      return 0
    fi
  fi

  ln -s "$src" "$dest"
  success "Created symlink: $dest -> $src"
}

# Main installation
main() {
  echo ""
  echo "======================================"
  echo "  Configuration Installation Script"
  echo "======================================"
  echo ""

  local os=$(detect_os)
  local pm=$(get_package_manager "$os")

  info "Detected OS: $os"
  info "Package manager: $pm"
  echo ""

  if [ "$pm" = "unknown" ]; then
    error "Could not detect package manager. Manual installation required."
    exit 1
  fi

  # Step 1: Install dependencies
  info "Checking dependencies..."
  echo ""

  local deps=("git" "fzf" "zoxide" "nvim" "tmux" "zsh")
  local pkg_names_brew=("git" "fzf" "zoxide" "neovim" "tmux" "zsh")
  local pkg_names_pacman=("git" "fzf" "zoxide" "neovim" "tmux" "zsh")
  local pkg_names_apt=("git" "fzf" "zoxide" "neovim" "tmux" "zsh")
  local pkg_names_dnf=("git" "fzf" "zoxide" "neovim" "tmux" "zsh")

  for i in "${!deps[@]}"; do
    local cmd="${deps[$i]}"
    if has_cmd "$cmd"; then
      success "$cmd is installed"
    else
      warn "$cmd is not installed"
      if confirm "Install $cmd?"; then
        case "$pm" in
          brew) install_package "${pkg_names_brew[$i]}" "$pm" ;;
          pacman) install_package "${pkg_names_pacman[$i]}" "$pm" ;;
          apt) install_package "${pkg_names_apt[$i]}" "$pm" ;;
          dnf) install_package "${pkg_names_dnf[$i]}" "$pm" ;;
        esac
        success "$cmd installed"
      fi
    fi
  done

  echo ""

  # Step 2: Install fonts
  if confirm "Install JetBrains Mono Nerd Font?"; then
    install_fonts "$os" "$pm"
  fi

  echo ""

  # Step 3: Create symlinks
  info "Setting up symlinks..."
  echo ""

  if confirm "Create symlink for .gitconfig?"; then
    create_symlink "$CONFIG_DIR/git/.gitconfig" "$HOME/.gitconfig"
  fi

  if confirm "Create symlink for .zshrc?"; then
    create_symlink "$CONFIG_DIR/zsh/.zshrc" "$HOME/.zshrc"
  fi

  echo ""

  # Step 4: Clone TPM for tmux
  info "Setting up tmux plugin manager..."
  local tpm_dir="$HOME/.tmux/plugins/tpm"

  if [ -d "$tpm_dir" ]; then
    success "TPM already installed"
  else
    if confirm "Install TPM (Tmux Plugin Manager)?"; then
      git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
      success "TPM installed"
      info "Run 'tmux' and press 'prefix + I' to install tmux plugins"
    fi
  fi

  echo ""

  # Step 5: Final notes
  echo "======================================"
  echo "  Installation Complete!"
  echo "======================================"
  echo ""
  info "Next steps:"
  echo "  1. Restart your terminal or run: source ~/.zshrc"
  echo "  2. If using tmux, press prefix + I to install plugins"
  echo "  3. Run 'p10k configure' if you want to customize the prompt"
  echo ""
}

main "$@"
