# Nix macOS Bootstrap

A one-shot bootstrap script to set up a complete Nix-managed development environment on macOS.

## Features

- Nix package manager with flakes support
- nix-darwin for macOS system configuration
- home-manager for user environment management
- LazyVim for Neovim with developer-focused plugins
- Enhanced terminal experience with Zsh, Starship, and modern CLI tools
- Development tools for multiple languages (Node.js, Python, Rust, Go, etc.)

## Quick Start

Run this command in your terminal:

```bash
bash <(curl -s https://raw.githubusercontent.com/grantis/nix-darwin-template/main/bootstrap.sh)
chmod +x bootstrap.sh
```

## Post-Installation

After installation:

1. Run `~/Templates/setup-lazyvim.sh` to configure LazyVim
2. Customize `~/nix/flake.nix` with additional packages as needed
3. Apply changes with `darwin-rebuild switch --flake ~/nix`
4. Launch a new terminal to enjoy your enhanced environment

### Adding Packages

Edit `~/nix/flake.nix` and add packages to the appropriate section:

```nix

home.packages = with pkgs; [
# Add your packages here
nodejs python3 rustup
];
```

