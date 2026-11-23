-- Claude Code in Neovim, as agent-shell in Emacs: the claude CLI in a split,
-- which sees the buffer and the selection and proposes its edits as diffs.
-- Needs `claude` on the PATH (installed in ~/.local/bin, logged in once).
return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  cmd = { "ClaudeCode", "ClaudeCodeFocus", "ClaudeCodeSend", "ClaudeCodeAdd" },
  opts = { terminal = { split_side = "right", split_width_percentage = 0.4 } },
  keys = {
    { "<leader>oc", "<cmd>ClaudeCode<cr>", desc = "Claude (agent)" },
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Claude: show/hide" },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Claude: focus" },
    { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Claude: resume a session" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Claude: add this file" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Claude: send the selection" },
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Claude: accept the diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Claude: reject the diff" },
  },
}
