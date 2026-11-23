-- Night Owl, as Emacs's anthe-night-owl
return {
  {
    "oxfist/night-owl.nvim",
    lazy = false,
    priority = 1000,
    opts = { italics = false },
    config = function(_, opts)
      require("night-owl").setup(opts)
    end,
  },
  -- LazyVim's themes, not used
  { "folke/tokyonight.nvim", enabled = false },
  { "catppuccin/nvim", name = "catppuccin", enabled = false },
}
