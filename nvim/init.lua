vim.g.mapleader = " "

local options = {
  number = true,
  relativenumber = true,
  expandtab = true,
  shiftwidth = 4,
  tabstop = 4,
  smartindent = true,
  ignorecase = true,
  smartcase = true,
  signcolumn = "yes",
  termguicolors = true,
  undofile = true,
  splitright = true,
  splitbelow = true,
  updatetime = 250,
}

for name, value in pairs(options) do
  vim.opt[name] = value
end

vim.keymap.set("n", "<leader>w", "<cmd>write<cr>", { desc = "Write file" })
vim.keymap.set("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit" })
