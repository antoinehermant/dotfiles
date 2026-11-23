-- Oil: folders as buffers, as dired (- goes up, Enter opens; edit the
-- buffer and :w to rename, move or delete). SPC - opens the file's folder.
return {
  "stevearc/oil.nvim",
  lazy = false, -- it opens the folders given to nvim
  dependencies = { "nvim-mini/mini.icons" },
  keys = { { "-", "<cmd>Oil<cr>", desc = "Parent folder (oil)" } },
  opts = {
    default_file_explorer = true,
    view_options = { show_hidden = true },
    keymaps = {
      ["q"] = { "actions.close", mode = "n" },
      ["<C-h>"] = false, -- keep window moves
      ["<C-l>"] = false,
      ["gr"] = "actions.refresh",
    },
  },
}
