#!/bin/bash
set -eo pipefail

REPO_URL="https://github.com/grantis/nix-darwin-template"
NIX_CONFIG_DIR="$HOME/nix"

echo "=== macOS Nix Development Environment Bootstrap ==="
echo "This script will set up a complete Nix-managed development environment."

# Function to handle errors
handle_error() {
  echo "Error occurred at line $1"
  echo "Setup failed. Please check the error message above."
  exit 1
}

# Set up error trap
trap 'handle_error $LINENO' ERR

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
  echo "Error: This script is designed for macOS only."
  exit 1
fi

# Step 1: Install Nix with proper daemon configuration
echo "Installing Nix..."
if ! command -v nix-env &> /dev/null; then
  echo "Downloading and running Nix installer..."
  sh <(curl -L https://nixos.org/nix/install) --daemon --darwin-use-unencrypted-nix-store-volume || {
    echo "Nix installation failed. Please check your internet connection and try again."
    exit 1
  }
  
  # Source nix environment immediately
  if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
    . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
  else
    echo "Warning: Nix environment file not found. You may need to restart your terminal."
  fi
else
  echo "✓ Nix already installed"
fi

# Verify Nix is working
if ! command -v nix-env &> /dev/null; then
  echo "Nix installation appears to have failed. Please restart your terminal and try again."
  exit 1
fi

# Step 2: Configure Nix with essential settings
echo "Configuring Nix..."
mkdir -p ~/.config/nix
cat > ~/.config/nix/nix.conf << EOF
experimental-features = nix-command flakes
allow-unfree = true
trusted-users = root $(whoami)
EOF

# Step 3: Clone the repository
echo "Cloning configuration repository..."
if [ -d "$NIX_CONFIG_DIR" ]; then
  echo "Configuration directory already exists. Updating..."
  cd "$NIX_CONFIG_DIR"
  git pull
else
  echo "Cloning fresh configuration..."
  git clone "$REPO_URL" "$NIX_CONFIG_DIR"
  cd "$NIX_CONFIG_DIR"
fi

# Step 4: Replace placeholders in flake.nix with actual values
echo "Customizing configuration for this machine..."
USERNAME=$(whoami)
HOSTNAME=$(scutil --get ComputerName 2>/dev/null || hostname)
sed -i '' "s/REPLACE_USERNAME/$USERNAME/g" "$NIX_CONFIG_DIR/flake.nix"
sed -i '' "s/REPLACE_HOSTNAME/$HOSTNAME/g" "$NIX_CONFIG_DIR/flake.nix"

# Step 5: Bootstrap nix-darwin
echo "Installing nix-darwin..."
nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer || {
  echo "Failed to build nix-darwin installer. Retrying with updated nixpkgs..."
  nix-channel --add https://nixos.org/channels/nixpkgs-unstable
  nix-channel --update
  nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
}

# Run the darwin installer
./result/bin/darwin-installer || {
  echo "Darwin installer failed. This might be due to an existing configuration."
  echo "Proceeding with setup anyway..."
}

# Step 6: Build and activate the configuration
echo "Building and activating nix-darwin configuration..."
cd "$NIX_CONFIG_DIR"
darwin-rebuild switch --flake .

echo "Bootstrap complete! Your Nix development environment is ready."
echo "You may need to restart your terminal or log out and back in to apply all changes."
echo ""
echo "To update your configuration in the future, edit $NIX_CONFIG_DIR/flake.nix and run:"
echo "  darwin-rebuild switch --flake $NIX_CONFIG_DIR"