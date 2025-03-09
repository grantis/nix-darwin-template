#!/bin/bash
set -eo pipefail

REPO_URL="https://github.com/grantis/nix-darwin-template.git"
SETUP_DIR="$HOME/.nix-bootstrap"

echo "=== macOS Nix Development Environment Bootstrap ==="
echo "This script will set up a complete Nix-managed development environment."

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
  echo "Error: This script is designed for macOS only."
  exit 1
fi

# Create setup directory
mkdir -p "$SETUP_DIR"
cd "$SETUP_DIR"

# Clone the repository or update if it exists
if [ -d "$SETUP_DIR/repo" ]; then
  echo "Updating existing repository..."
  cd "$SETUP_DIR/repo"
  git pull
else
  echo "Cloning bootstrap repository..."
  git clone "$REPO_URL" "$SETUP_DIR/repo"
  cd "$SETUP_DIR/repo"
fi

# Make scripts executable
chmod +x install.sh

# Run the setup script
./install.sh

echo "Bootstrap complete! Your Nix development environment is ready."
echo "You may need to restart your terminal to apply all changes."