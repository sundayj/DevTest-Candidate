#!/usr/bin/env bash

set -e

echo "🐧 DevTest Linux Setup Script"
echo "=============================="
echo ""

# Warning about Docker Desktop
echo "⚠️  IMPORTANT: This script installs the native Linux Docker engine (docker.io)"
echo "   Do NOT use Docker Desktop on Linux - use the built-in Linux Docker instead!"
echo ""

ask_confirm() {
  read -p "$1 [y/N] " -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]]
}

check_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "🐳 Docker not found."
    if ask_confirm "Install Docker (docker.io) using apt?"; then
      sudo apt-get update && sudo apt-get install -y docker.io
      sudo systemctl enable docker
      sudo systemctl start docker
      sudo usermod -aG docker $USER
      echo "✅ Docker installed. You may need to log out and back in for group changes to take effect."
    else
      echo "❌ Skipping Docker installation."
      echo ""
      echo "📋 Manual Docker Installation Instructions:"
      echo "   You can install Docker manually using one of these methods:"
      echo ""
      echo "   Method 1 - Using apt (recommended):"
      echo "   sudo apt-get update"
      echo "   sudo apt-get install -y docker.io"
      echo "   sudo systemctl enable docker"
      echo "   sudo systemctl start docker"
      echo "   sudo usermod -aG docker \$USER"
      echo ""
      echo "   Method 2 - Official Docker installation:"
      echo "   Visit: https://docs.docker.com/engine/install/ubuntu/"
      echo ""
      echo "   ⚠️  IMPORTANT: Use the native Linux Docker engine, NOT Docker Desktop!"
      echo ""
      return 1
    fi
  else
    echo "✅ Docker is already installed: $(docker --version)"
  fi
}

check_compose() {
  if command -v docker-compose >/dev/null 2>&1; then
    echo "✅ docker-compose is installed: $(docker-compose --version)"
  elif docker compose version >/dev/null 2>&1; then
    echo "✅ Docker Compose (v2) is available via 'docker compose'"
  else
    echo "🔧 Docker Compose not found."
    if ask_confirm "Install Docker Compose plugin using apt?"; then
      sudo apt-get update && sudo apt-get install -y docker-compose-plugin
      echo "✅ Docker Compose plugin installed."
    else
      echo "❌ Skipping Docker Compose installation."
      echo ""
      echo "📋 Manual Docker Compose Installation Instructions:"
      echo "   You can install Docker Compose manually using one of these methods:"
      echo ""
      echo "   Method 1 - Using apt (recommended):"
      echo "   sudo apt-get update"
      echo "   sudo apt-get install -y docker-compose-plugin"
      echo ""
      echo "   Method 2 - Download binary directly:"
      echo "   Visit: https://docs.docker.com/compose/install/linux/"
      echo ""
      echo "   Method 3 - Using pip:"
      echo "   pip install docker-compose"
      echo ""
      return 1
    fi
  fi
}

check_devcontainer() {
  if ! command -v devcontainer >/dev/null 2>&1; then
    echo "📦 Dev Containers CLI not found."
    if ask_confirm "Install Dev Containers CLI using curl?"; then
      if command -v curl >/dev/null 2>&1; then
        curl -fsSL https://raw.githubusercontent.com/devcontainers/cli/main/install.sh | sh
        echo "✅ Dev Containers CLI installed."
      else
        echo "❌ curl not found. Please install curl first."
        echo ""
        echo "📋 Install curl first:"
        echo "   sudo apt-get update && sudo apt-get install -y curl"
        echo ""
        return 1
      fi
    else
      echo "❌ Skipping Dev Containers CLI installation."
      echo ""
      echo "📋 Manual Dev Containers CLI Installation Instructions:"
      echo "   You can install Dev Containers CLI manually using one of these methods:"
      echo ""
      echo "   Method 1 - Using curl (recommended):"
      echo "   curl -fsSL https://raw.githubusercontent.com/devcontainers/cli/main/install.sh | sh"
      echo ""
      echo "   Method 2 - Using npm (if you have Node.js):"
      echo "   npm install -g @devcontainers/cli"
      echo ""
      echo "   Method 3 - Download from GitHub:"
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

  check_docker
  check_compose
  check_devcontainer
  install_vscode_extension
  setup_environment

  echo ""
  echo "🎉 Setup completed!"
  echo ""
  echo "Next steps:"
  echo "1. Start development environment:"
  echo "   • DevContainer: devcontainer up --workspace-folder ."
  echo "   • Docker Compose: docker-compose up -d"
  echo "2. Access application at http://localhost:8001"
  echo ""
  echo "If you installed Docker for the first time, you may need to:"
  echo "• Log out and back in (for group permissions)"
  echo "• Or run: newgrp docker"
}

main "$@"
