{
  description = "Full Stack Developer macOS Setup with Enhanced Terminal Experience";

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

  outputs = inputs@{ darwin, home-manager, nixpkgs, ... }:
  let
    username = "REPLACE_USERNAME";
    hostname = "REPLACE_HOSTNAME";
  in
  {
    darwinConfigurations."${hostname}" = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        ({ pkgs, ... }: {
          # Core system configuration
          nix.settings = {
            experimental-features = "nix-command flakes";
            trusted-users = ["root" username];
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
              "alacritty"  # Terminal emulator with good performance
              "kitty"      # Another modern terminal option
            ];
            masApps = {
              Xcode = 497799835;
            };
          };

          # User environment configuration
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users."${username}" = { config, lib, ... }: {
            home.packages = with pkgs; [
              # Development tools
              nodejs_20 bun deno python311 
              rustup go postgresql_15 redis
              docker-compose kubectl terraform

              # CLI utilities
              neovim tmux ripgrep fd bat jq fzf
              yq zoxide gh tldr exa htop
              
              # LazyVim dependencies
              lazygit delta luajit stylua
              tree-sitter nodejs
              
              # Terminal enhancements
              starship nnn
              
              # For Zsh & plugins
              zsh-syntax-highlighting
              zsh-autosuggestions
              zsh-history-substring-search
              nix-zsh-completions
            ];

            programs.git = {
              enable = true;
              userName = "Your Name";
              userEmail = "your.email@example.com";
              extraConfig = {
                init.defaultBranch = "main";
                pull.rebase = false;
                core.editor = "nvim";
                core.pager = "delta";
                interactive.diffFilter = "delta --color-only";
                delta = {
                  navigate = true;
                  light = false;
                  side-by-side = true;
                };
              };
            };

            programs.fzf = {
              enable = true;
              enableZshIntegration = true;
              defaultCommand = "fd --type f --hidden --follow --exclude .git";
              defaultOptions = ["--height 40%" "--layout=reverse" "--border"];
            };

            programs.starship = {
              enable = true;
              enableZshIntegration = true;
              settings = {
                add_newline = false;
                character = {
                  success_symbol = "[➜](bold green)";
                  error_symbol = "[✗](bold red)";
                };
                nodejs.disabled = false;
                package.disabled = true;
              };
            };

            programs.tmux = {
              enable = true;
              shortcut = "a";
              terminal = "screen-256color";
              escapeTime = 0;
              historyLimit = 50000;
              plugins = with pkgs.tmuxPlugins; [
                sensible
                vim-tmux-navigator
                resurrect
                continuum
                yank
              ];
              extraConfig = ''
                set -g mouse on
                set-option -g focus-events on

                # Start window numbering at 1
                set -g base-index 1
                set -g pane-base-index 1

                # Status bar
                set -g status-style bg=default
                set -g status-left "#[fg=green]#S "
                set -g status-right "#[fg=cyan]%a %d %b %R"
              '';
            };

            programs.neovim = {
              enable = true;
              defaultEditor = true;
              viAlias = true;
              vimAlias = true;
              withNodeJs = true;
              withPython3 = true;
              extraPackages = with pkgs; [
                tree-sitter
                luajitPackages.luarocks
                nodejs
                ripgrep
                fd
              ];
            };

            programs.zsh = {
              enable = true;
              enableCompletion = true;
              enableAutosuggestions = true;
              syntaxHighlighting.enable = true;
              historySubstringSearch.enable = true;
              
              oh-my-zsh = {
                enable = true;
                plugins = [ 
                  "git" "docker" "aws" "npm" "node" "python" 
                  "rust" "golang" "kubectl" "terraform"
                  "fzf" "z" "extract" "colored-man-pages"
                  "command-not-found" "sudo" "copypath"
                  "copybuffer" "dirhistory" "history"
                ];
                theme = "robbyrussell";
              };
              
              shellAliases = {
                ll = "exa -la --icons";
                ls = "exa --icons";
                la = "exa -a --icons";
                lt = "exa -T --icons";
                g = "git";
                ga = "git add";
                gc = "git commit";
                gco = "git checkout";
                gp = "git push";
                gpl = "git pull";
                gs = "git status";
                gd = "git diff";
                k = "kubectl";
                tf = "terraform";
                nrs = "darwin-rebuild switch --flake ~/nix";
                vim = "nvim";
                vi = "nvim";
                v = "nvim";
                lg = "lazygit";
                cat = "bat";
                find = "fd";
                grep = "rg";
              };
              
              initExtra = ''
                # Better history search with up/down arrows
                bindkey '^[[A' history-substring-search-up
                bindkey '^[[B' history-substring-search-down
                
                # Initialize starship prompt
                eval "$(starship init zsh)"
                
                # Initialize zoxide (smart cd command)
                eval "$(zoxide init zsh)"
                
                # Set environment variables
                export EDITOR="nvim"
                export VISUAL="nvim"
                export TERM="xterm-256color"
                export PATH="$HOME/.local/bin:$PATH"
                
                # Additional FZF functions
                # ctrl+r for history search
                bindkey '^R' fzf-history-widget
                
                # ctrl+t for file search
                bindkey '^T' fzf-file-widget
                
                # More advanced cd with preview
                function fcd() {
                  local dir
                  dir=$(fd --type d | fzf --preview 'exa --tree --level=1 {}') && cd "$dir"
                }
                
                # Search for files and open in neovim
                function fvim() {
                  local file
                  file=$(fd --type f | fzf --preview 'bat --color=always --style=numbers {}') && nvim "$file"
                }
                
                # Enable LazyVim tips
                function nvim-help() {
                  echo "LazyVim Quick Tips:"
                  echo " - <Space> opens command menu"
                  echo " - <Space>ff find files"
                  echo " - <Space>/ search in files"
                  echo " - <Space>gg lazygit"
                  echo " - <leader>lr rename symbol"
                  echo " - <leader>ca code actions"
                }
              '';
            };

            programs.direnv = {
              enable = true;
              nix-direnv.enable = true;
            };
            
            home.file.".config/nvim/.keep".text = "";
            
            # This value determines the Home Manager release that your configuration is
            # compatible with. This helps avoid breakage when a new Home Manager release
            # introduces backwards incompatible changes.
            home.stateVersion = "23.11";
          };
        })
        home-manager.darwinModules.home-manager
      ];
    };
  };
}