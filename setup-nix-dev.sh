#!/bin/bash
set -eo pipefail

# Function to handle errors
handle_error() {
  echo "Error occurred at line $1"
  echo "Setup failed. Please check the error message above."
  exit 1
}

# Set up error trap
trap 'handle_error $LINENO' ERR

echo "=== Setting up Nix-Darwin Development Environment with LazyVim ==="

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

# Step 3: Bootstrap nix-darwin properly
echo "Installing nix-darwin..."
nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer || {
  echo "Failed to build nix-darwin installer. Retrying with updated nixpkgs..."
  nix-channel --add https://nixos.org/channels/nixpkgs-unstable
  nix-channel --update
  nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
}

# Create the nix directory if it doesn't exist
mkdir -p ~/nix

# Run the darwin installer
./result/bin/darwin-installer --flake ~/nix || {
  echo "Darwin installer failed. This might be due to an existing configuration."
  echo "Proceeding with setup anyway..."
}

# Step 4: Create directory structure
echo "Creating directory structure..."
mkdir -p ~/nix/{modules,packages} ~/Templates ~/.config/nvim

# Step 5: Generate optimized flake.nix with enhanced Zsh and LazyVim support
cat > ~/nix/flake.nix << 'EOF'
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
              "alacritty"  # Terminal emulator with good performance
              "kitty"      # Another modern terminal option
            ];
            masApps = {
              Xcode = 497799835;
            };
          };

          # User environment configuration
          home-manager.users."${user}" = { config, lib, ... }: {
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
          };
        })
      ];
    };
  };
}
EOF

# Step 6: Create LazyVim setup script
mkdir -p ~/.config/nvim
cat > ~/Templates/setup-lazyvim.sh << 'EOF'
#!/bin/bash
set -eo pipefail

NVIM_CONFIG="$HOME/.config/nvim"

echo "Setting up LazyVim in $NVIM_CONFIG..."

# Backup existing config if it exists
if [ -d "$NVIM_CONFIG" ] && [ "$(ls -A "$NVIM_CONFIG")" ]; then
  echo "Backing up existing Neovim configuration..."
  mv "$NVIM_CONFIG" "$NVIM_CONFIG.bak.$(date +%Y%m%d%H%M%S)"
  mkdir -p "$NVIM_CONFIG"
fi

# Clone LazyVim starter
echo "Cloning LazyVim starter configuration..."
git clone https://github.com/LazyVim/starter "$NVIM_CONFIG"
rm -rf "$NVIM_CONFIG/.git"

# Customize init.lua with additional plugins for dev experience
cat > "$NVIM_CONFIG/lua/plugins/extras.lua" << 'EOLUA'
return {
  -- Git integration
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "Gstatus", "Gblame", "Gpush", "Gpull" },
    keys = {
      { "<leader>gs", "<cmd>Git<cr>", desc = "Git Status" },
      { "<leader>gb", "<cmd>Git blame<cr>", desc = "Git Blame" },
    },
  },

  -- Improved terminal handling
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = true,
    keys = {
      { "<leader>tt", "<cmd>ToggleTerm direction=float<cr>", desc = "Float Terminal" },
      { "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Horizontal Terminal" },
    },
  },

  -- Autocomplete and snippets enhancements
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-emoji",
      "petertriho/cmp-git",
    },
    opts = function(_, opts)
      local cmp = require("cmp")
      opts.sources = cmp.config.sources(vim.list_extend(opts.sources, {
        { name = "emoji" },
        { name = "git" },
      }))
    end,
  },

  -- Code runner
  {
    "stevearc/overseer.nvim",
    keys = {
      { "<leader>or", "<cmd>OverseerRun<cr>", desc = "Run Task" },
      { "<leader>ot", "<cmd>OverseerToggle<cr>", desc = "Toggle Tasks" },
    },
    opts = {},
  },

  -- Enhanced syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "BufReadPre",
    config = true,
  },

  -- Nix support
  {
    "LnL7/vim-nix",
    ft = "nix",
  },
}
EOLUA

# Set up custom settings for developer experience
cat > "$NVIM_CONFIG/lua/config/options.lua" << 'EOLUA'
-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- General
vim.g.mapleader = " " -- Use space as leader key
vim.opt.clipboard = "unnamedplus" -- Use system clipboard
vim.opt.undofile = true -- Persistent undo
vim.opt.swapfile = false -- No swap file

-- UI
vim.opt.number = true -- Line numbers
vim.opt.relativenumber = true -- Relative line numbers
vim.opt.termguicolors = true -- True color support
vim.opt.cursorline = true -- Highlight current line
vim.opt.scrolloff = 8 -- Keep 8 lines above/below cursor
vim.opt.sidescrolloff = 8 -- Keep 8 columns left/right of cursor
vim.opt.showmode = false -- Don't show mode (shown in statusline)
vim.opt.showmatch = true -- Highlight matching brackets
vim.opt.signcolumn = "yes" -- Always show sign column

-- Editing
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.smartindent = true -- Insert indents automatically
vim.opt.wrap = false -- No line wrap
vim.opt.shiftwidth = 2 -- Size of an indent
vim.opt.tabstop = 2 -- Number of spaces tabs count for
vim.opt.ignorecase = true -- Ignore case in search
vim.opt.smartcase = true -- Don't ignore case with capitals

-- Development focused
vim.opt.list = true -- Show some invisible characters
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" } -- Show invisible characters
vim.opt.splitright = true -- Put new windows right of current
vim.opt.splitbelow = true -- Put new windows below current
EOLUA

# Set up additional keymaps for developer experience
cat > "$NVIM_CONFIG/lua/config/keymaps.lua" << 'EOLUA'
-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local function map(mode, lhs, rhs, opts)
  local options = { noremap = true, silent = true }
  if opts then
    options = vim.tbl_extend("force", options, opts)
  end
  vim.keymap.set(mode, lhs, rhs, options)
end

-- File explorer toggle with sidebar
map("n", "<leader>e", "<cmd>Neotree toggle<cr>", { desc = "Toggle Explorer" })

-- Terminal shortcuts with toggleterm
map("n", "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", { desc = "Terminal Float" })
map("n", "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>", { desc = "Terminal Horizontal" })
map("n", "<leader>tv", "<cmd>ToggleTerm direction=vertical<cr>", { desc = "Terminal Vertical" })

-- Improved window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- Better buffer navigation
map("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
map("n", "[b", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer" })
map("n", "]b", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })

-- Quickfix list navigation
map("n", "[q", "<cmd>cprev<cr>", { desc = "Previous quickfix" })
map("n", "]q", "<cmd>cnext<cr>", { desc = "Next quickfix" })

-- Useful developer shortcuts
map("n", "<leader>fw", "<cmd>w<cr>", { desc = "Save" })
map("n", "<leader>fa", "<cmd>wa<cr>", { desc = "Save all" })
map("n", "<leader>qq", "<cmd>q<cr>", { desc = "Quit" })
map("n", "<leader>qa", "<cmd>qa<cr>", { desc = "Quit all" })

-- Split management
map("n", "<leader>\\", "<cmd>vsplit<cr>", { desc = "Vertical Split" })
map("n", "<leader>-", "<cmd>split<cr>", { desc = "Horizontal Split" })

-- Code actions
map("n", "<leader>cf", vim.lsp.buf.format, { desc = "Format Document" })
map("v", "<leader>cf", vim.lsp.buf.format, { desc = "Format Selection" })
map("n", "<leader>cr", vim.lsp.buf.rename, { desc = "Rename Symbol" })
map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action" })

-- Movement in insert mode
map("i", "<C-h>", "<Left>", { desc = "Move left" })
map("i", "<C-j>", "<Down>", { desc = "Move down" })
map("i", "<C-k>", "<Up>", { desc = "Move up" })
map("i", "<C-l>", "<Right>", { desc = "Move right" })

-- Terminal mode improvements
map("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
map("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc = "Go to left window" })
map("t", "<C-j>", "<C-\\><C-n><C-w>j", { desc = "Go to lower window" })
map("t", "<C-k>", "<C-\\><C-n><C-w>k", { desc = "Go to upper window" })
map("t", "<C-l>", "<C-\\><C-n><C-w>l", { desc = "Go to right window" })

-- Better indentation
map("v", "<", "<gv", { desc = "Unindent line" })
map("v", ">", ">gv", { desc = "Indent line" })

-- Diagnostics
map("n", "<leader>xx", "<cmd>TroubleToggle document_diagnostics<cr>", { desc = "Document Diagnostics" })
map("n", "<leader>xw", "<cmd>TroubleToggle workspace_diagnostics<cr>", { desc = "Workspace Diagnostics" })
map("n", "<leader>xl", "<cmd>TroubleToggle loclist<cr>", { desc = "Location List" })
map("n", "<leader>xq", "<cmd>TroubleToggle quickfix<cr>", { desc = "Quickfix List" })
EOLUA

echo "LazyVim setup complete!"
echo "Run 'nvim' to start using LazyVim. Initial startup will install plugins automatically."
echo "Check out the key bindings with <Space> to see available commands."
EOF

chmod +x ~/Templates/setup-lazyvim.sh

# Step 7: Apply initial configuration
echo "Applying base configuration..."
darwin-rebuild switch --flake ~/nix

echo "=== Enhanced Setup Complete ==="
echo "Next steps:"
echo "1. Run ~/Templates/setup-lazyvim.sh to install and configure LazyVim"
echo "2. Customize ~/nix/flake.nix with additional packages as needed"
echo "3. Use 'darwin-rebuild switch --flake ~/nix' after changes"
echo "4. Launch a new terminal to enjoy your enhanced Zsh experience"