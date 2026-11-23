-- Telescope, for SPC . (config/find_file.lua): its file browser. The other
-- pickers are LazyVim's (Snacks).
return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope-file-browser.nvim" },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      telescope.setup({
        defaults = {
          mappings = {
            i = { ["<C-j>"] = actions.move_selection_next, ["<C-k>"] = actions.move_selection_previous },
          },
        },
      })
      telescope.load_extension("file_browser")
    end,
  },
  { "nvim-telescope/telescope-file-browser.nvim", lazy = true },
}
