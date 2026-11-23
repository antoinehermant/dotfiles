-- Neogit, magit's clone: SPC g g
return {
  "NeogitOrg/neogit",
  cmd = "Neogit",
  dependencies = { "nvim-lua/plenary.nvim", "sindrets/diffview.nvim" },
  opts = { kind = "replace", integrations = { diffview = true, snacks = true } },
}
