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