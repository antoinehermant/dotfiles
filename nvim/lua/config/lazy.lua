-- The plugins, with lazy.nvim. With $NVIM_LOCAL (on UBELIX: a folder of the
-- login node's local disk, unpacked from one archive by bin/nvim-plugins, as
-- the home's network storage is slow to read many small files), all that is
-- read at the start is there: the plugins (lazy/), the syntax parsers
-- (site/) and the language servers (mason/). Else the usual ~/.local/share/nvim.
local here = vim.env.NVIM_LOCAL
local root = here and (here .. "/lazy") or (vim.fn.stdpath("data") .. "/lazy")
local lazypath = root .. "/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { "Failed to clone lazy.nvim:\n", "ErrorMsg" }, { out, "WarningMsg" } }, true, {})
    return
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  root = root,
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins", opts = { colorscheme = "night-owl" } },
    { import = "plugins" },
    here and { "nvim-treesitter/nvim-treesitter", opts = { install_dir = here .. "/site" } } or {},
    here and { "mason-org/mason.nvim", opts = { install_root_dir = here .. "/mason" } } or {},
  },
  defaults = {
    -- Each plugin loads when first needed: the start reads fewer files
    lazy = true,
    version = false,
  },
  install = { colorscheme = { "night-owl", "habamax" } },
  -- No update check at each start: :Lazy sync when I choose
  checker = { enabled = false },
  change_detection = { notify = false },
  performance = {
    -- Lua's byte-code cache is in ~/.cache, on the slow storage: off there
    cache = { enabled = not here },
    rtp = {
      disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin", "netrwPlugin" },
    },
  },
})
