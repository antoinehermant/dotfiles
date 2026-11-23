-- Parsers are built with the tree-sitter CLI. Where it doesn't run (UBELIX:
-- the prebuilt one, Mason's too, needs a newer glibc), install none, or
-- each start would try them all again and fail: Neovim's own parsers (lua,
-- c, markdown, vim, query) still work, the other languages get Vim's syntax.
local function cli_runs()
  return vim.fn.executable("tree-sitter") == 1
    and vim.system({ "tree-sitter", "--version" }):wait().code == 0
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if not cli_runs() then
        opts.ensure_installed = {}
      end
    end,
  },
}
