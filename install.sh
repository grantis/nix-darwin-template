#!/bin/bash
# install.sh
set -eo pipefail

# Function to handle errors
handle_error() {
  echo "Error occurred at line $1"
  echo "Setup failed. Please check the error message above."
  exit 1
}

# Set up error trap
trap 'handle_error $LINENO' ERR

echo "=== Setting up Nix-Darwin Development Environment ==="

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

# Use the existing nix.conf file if available
if [ -f "./nix.conf" ]; then
  echo "Using existing nix.conf file..."
  cp "./nix.conf" ~/.config/nix/nix.conf
else
  echo "Creating default nix.conf..."
  cat > ~/.config/nix/nix.conf << EOF
experimental-features = nix-command flakes
allow-unfree = true
trusted-users = root $(whoami)
EOF
fi

# Step 3: Bootstrap nix-darwin properly
echo "Installing nix-darwin..."
nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer || {
  echo "Failed to build nix-darwin installer. Retrying with updated nixpkgs..."
  nix-channel --add https://nixos.org/channels/nixpkgs-unstable
  nix-channel --update
  nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
}

# Run the darwin installer
./result/bin/darwin-installer --flake ~/nix || {
  echo "Darwin installer failed. This might be due to an existing configuration."
  echo "Proceeding with setup anyway..."
}

# Step 4: Create directory structure
echo "Creating directory structure..."
mkdir -p ~/nix/{modules,packages} ~/Templates ~/.config/nvim

# Step 5: Use existing flake.nix file
echo "Using existing flake.nix file..."
FLAKE_SOURCE="./flake.nix"
FLAKE_DEST="$HOME/nix/flake.nix"

if [ -f "$FLAKE_SOURCE" ]; then
  echo "Found flake.nix file. Copying to $FLAKE_DEST..."
  mkdir -p "$(dirname "$FLAKE_DEST")"
  cp "$FLAKE_SOURCE" "$FLAKE_DEST"
else
  echo "Error: flake.nix file not found at $FLAKE_SOURCE"
  echo "Please make sure the file exists in the expected location."
  exit 1
fi

# Step 7: Apply initial configuration
echo "Applying base configuration..."
darwin-rebuild switch --flake ~/nix

echo "=== Enhanced Setup Complete ==="
echo "Next steps:"
echo "1. Customize ~/nix/flake.nix with additional packages as needed"
echo "2. Use 'darwin-rebuild switch --flake ~/nix' after changes"
echo "3. Launch a new terminal to enjoy your enhanced development environment"