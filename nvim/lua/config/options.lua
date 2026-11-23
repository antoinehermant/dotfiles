-- Options, after LazyVim's
vim.g.snacks_animate = false
-- Line numbers relative, as Doom's
vim.opt.relativenumber = true
-- Over SSH (UBELIX), a yank goes to the laptop's clipboard (OSC 52, through tmux)
if vim.env.SSH_TTY or vim.env.TMUX then
  vim.g.clipboard = "osc52"
end
-- Netrw off: oil.nvim browses folders
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
