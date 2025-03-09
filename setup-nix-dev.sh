#!/bin/bash
set -eo pipefail

echo "=== Setting up Nix-Darwin Development Environment ==="

# Step 1: Install Nix with proper daemon configuration
echo "Installing Nix..."
if ! command -v nix-env &> /dev/null; then
  sh <(curl -L https://nixos.org/nix/install) --daemon --darwin-use-unencrypted-nix-store-volume
  # Source nix environment immediately
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
else
  echo "✓ Nix already installed"
fi

# Step 2: Configure Nix with essential settings
mkdir -p ~/.config/nix
cat > ~/.config/nix/nix.conf << EOF
experimental-features = nix-command flakes
allow-unfree = true
trusted-users = root $(whoami)
EOF

# Step 3: Bootstrap nix-darwin properly
echo "Installing nix-darwin..."
nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
./result/bin/darwin-installer --flake ~/nix

# Step 4: Create directory structure
mkdir -p ~/nix/{modules,packages} ~/Templates

# Step 5: Generate optimized flake.nix
cat > ~/nix/flake.nix << 'EOF'
{
  description = "Full Stack Developer macOS Setup";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ darwin, home-manager, ... }:
  let
    user = "$(whoami)";
    hostname = "$(scutil --get ComputerName)";
  in
  {
    darwinConfigurations."${hostname}" = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        ({ pkgs, ... }: {
          # Core system configuration
          nix.settings = {
            experimental-features = "nix-command flakes";
            trusted-users = ["root" "${user}"];
          };

          services.nix-daemon.enable = true;

          # System-wide packages
          environment.systemPackages = with pkgs; [
            git curl wget gnupg pinentry-mac
          ];

          # macOS system settings
          system.defaults = {
            dock = {
              autohide = true;
              show-recents = false;
              mru-spaces = false;
            };
            finder = {
              AppleShowAllExtensions = true;
              FXEnableExtensionChangeWarning = false;
            };
            NSGlobalDomain = {
              ApplePressAndHoldEnabled = false;
              InitialKeyRepeat = 15;
              KeyRepeat = 2;
            };
          };

          # Homebrew configuration
          homebrew = {
            enable = true;
            casks = [
              "visual-studio-code"
              "docker"
              "postman"
              "iterm2"
              "obsidian"
              "rectangle"
            ];
            masApps = {
              Xcode = 497799835;
            };
          };

          # User environment configuration
          home-manager.users."${user}" = {
            home.packages = with pkgs; [
              # Development tools
              nodejs_20 bun deno python311 
              rustup go postgresql_15 redis
              docker-compose kubectl terraform

              # CLI utilities
              neovim tmux ripgrep fd bat jq 
              yq zoxide gh tldr
            ];

            programs.git = {
              enable = true;
              userName = "Your Name";
              userEmail = "your.email@example.com";
              extraConfig = {
                init.defaultBranch = "main";
                pull.rebase = false;
              };
            };

            programs.zsh = {
              enable = true;
              enableAutosuggestions = true;
              oh-my-zsh = {
                enable = true;
                plugins = [ "git" "docker" "aws" "node" "python" ];
                theme = "robbyrussell";
              };
              shellAliases = {
                ll = "ls -la";
                g = "git";
                k = "kubectl";
                tf = "terraform";
                nrs = "darwin-rebuild switch --flake ~/nix";
              };
              initExtra = ''
                eval "$(zoxide init zsh)"
                export PATH="$HOME/.local/bin:$PATH"
              '';
            };

            programs.direnv = {
              enable = true;
              nix-direnv.enable = true;
            };
          };
        })
      ];
    };
  };
}
EOF

# Step 6: Apply initial configuration
echo "Applying base configuration..."
darwin-rebuild switch --flake ~/nix

# Step 7: Create improved development templates
mkdir -p ~/Templates
cat > ~/Templates/shell.nix << 'EOF'
{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  buildInputs = with pkgs; [
    nodejs_20
    python311
    postgresql_15
    docker-compose
    kubectl
  ];

  shellHook = ''
    export PGDATA="$PWD/.postgres_data"
    export DATABASE_URL="postgresql://localhost:5432/$(basename $PWD)"
    
    # Initialize PostgreSQL if needed
    if [[ ! -d $PGDATA ]]; then
      initdb --locale=C -E UTF-8
      echo "PostgreSQL cluster initialized in $PGDATA"
    fi
  '';
}
EOF

echo "=== Setup Complete ==="
echo "Next steps:"
echo "1. Customize ~/nix/flake.nix with additional packages"
echo "2. Run 'nix-shell ~/Templates/shell.nix' in project directories"
echo "3. Use 'darwin-rebuild switch --flake ~/nix' after changes"