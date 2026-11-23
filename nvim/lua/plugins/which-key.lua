-- The names of my key groups, shown by which-key
return {
  "folke/which-key.nvim",
  opts = {
    spec = {
      { "<leader>k", group = "mine" },
      { "<leader>kq", group = "slurm" },
      { "<leader>o", group = "open" },
      { "<leader>a", group = "agent (Claude)" },
      { "<leader>p", group = "project" },
    },
  },
}
