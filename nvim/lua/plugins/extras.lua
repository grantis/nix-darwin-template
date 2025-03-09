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