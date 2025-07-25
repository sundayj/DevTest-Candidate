#!/usr/bin/env bash
set -e

echo "🍎 DevTest macOS Setup Script"
echo "============================="
echo ""

ask_confirm() {
  read -p "$1 [y/N] " -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]]
}

check_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    echo "🍺 Homebrew not found."
    if ask_confirm "Install Homebrew first?"; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      echo "✅ Homebrew installed."
    else
      echo "❌ Homebrew is required for this setup script."
      echo ""
      echo "📋 Manual Homebrew Installation Instructions:"
      echo "   Homebrew is the recommended package manager for macOS."
      echo "   You can install it manually using:"
      echo ""
      echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
      echo ""
      echo "   📖 Visit: https://brew.sh for more information"
      echo ""
      echo "   Alternative: You can install tools manually without Homebrew,"
      echo "   but it will be more complex. See individual tool documentation."
      echo ""
      return 1
    fi
  else
    echo "✅ Homebrew is already installed: $(brew --version | head -1)"
  fi
}

check_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "🐳 Docker not found."
    if ask_confirm "Install Docker Desktop using Homebrew?"; then
      brew install --cask docker
      echo "✅ Docker Desktop installed. Please start Docker Desktop from Applications."
    else
      echo "❌ Skipping Docker installation."
      echo ""
      echo "📋 Manual Docker Installation Instructions:"
      echo "   You can install Docker Desktop manually using one of these methods:"
      echo ""
      echo "   Method 1 - Using Homebrew (recommended):"
      echo "   brew install --cask docker"
      echo ""
      echo "   Method 2 - Download directly from Docker:"
      echo "   Visit: https://docs.docker.com/desktop/install/mac/"
      echo "   Download the .dmg file for your Mac architecture (Intel or Apple Silicon)"
      echo ""
      echo "   Method 3 - Using MacPorts (if you prefer):"
      echo "   sudo port install docker"
      echo ""
      echo "   📖 After installation, start Docker Desktop from Applications"
      echo ""
      return 1
    fi
  else
    echo "✅ Docker is already installed: $(docker --version)"
  fi
}

check_devcontainer() {
  if ! command -v devcontainer >/dev/null 2>&1; then
    echo "📦 Dev Containers CLI not found."
    if ask_confirm "Install Dev Containers CLI using Homebrew?"; then
      brew install devcontainer
      echo "✅ Dev Containers CLI installed."
    else
      echo "❌ Skipping Dev Containers CLI installation."
      echo ""
      echo "📋 Manual Dev Containers CLI Installation Instructions:"
      echo "   You can install Dev Containers CLI manually using one of these methods:"
      echo ""
      echo "   Method 1 - Using Homebrew (recommended):"
      echo "   brew install devcontainer"
      echo ""
      echo "   Method 2 - Using curl:"
      echo "   curl -fsSL https://raw.githubusercontent.com/devcontainers/cli/main/install.sh | sh"
      echo ""
      echo "   Method 3 - Using npm (if you have Node.js):"
      echo "   npm install -g @devcontainers/cli"
      echo ""
      echo "   Method 4 - Download from GitHub:"
      echo "   Visit: https://github.com/devcontainers/cli"
      echo ""
      echo "   📖 Documentation: https://containers.dev/supporting"
      echo ""
      return 1
    fi
  else
    echo "✅ Dev Containers CLI is installed: $(devcontainer --version)"
  fi
}

install_vscode_extension() {
  if command -v code >/dev/null 2>&1; then
    if ! code --list-extensions | grep -q ms-vscode-remote.remote-containers; then
      echo "🔌 VS Code detected without Dev Containers extension."
      if ask_confirm "Install VS Code Dev Containers extension?"; then
        code --install-extension ms-vscode-remote.remote-containers
        echo "✅ VS Code Dev Containers extension installed."
      else
        echo "❌ Skipping VS Code extension installation."
      fi
    else
      echo "✅ VS Code Dev Containers extension is already installed."
    fi
  else
    echo "ℹ️  VS Code not found - skipping extension installation."
  fi
}

setup_environment() {
  WORKSPACE_PATH="$(cd "$(dirname "$0")/.." && pwd)"
  ENV_EXAMPLE="$WORKSPACE_PATH/.env.example"
  ENV_TARGET="$WORKSPACE_PATH/.devcontainer/.env"

  if [ ! -f "$ENV_TARGET" ]; then
    if [ -f "$ENV_EXAMPLE" ]; then
      cp "$ENV_EXAMPLE" "$ENV_TARGET"
      echo "✅ Environment file copied from .env.example to .devcontainer/.env"
    else
      echo "⚠️  Warning: .env.example not found - you may need to create .devcontainer/.env manually"
    fi
  else
    echo "✅ Environment file already exists at .devcontainer/.env"
  fi
}

main() {
  echo "🔍 Checking required tools..."
  echo ""

  check_homebrew
  check_docker
  check_devcontainer
  install_vscode_extension
  setup_environment

  echo ""
  echo "🎉 Setup completed!"
  echo ""
  echo "Next steps:"
  echo "1. Make sure Docker Desktop is running"
  echo "2. Start development environment:"
  echo "   • DevContainer: devcontainer up --workspace-folder ."
  echo "   • Docker Compose: docker-compose up -d"
  echo "3. Access application at http://localhost:8001"
}

main "$@"
