-- Autocommands, after LazyVim's

-- A NetCDF file opens in ncview (an X window), not as text
vim.api.nvim_create_autocmd("BufReadCmd", {
  pattern = { "*.nc", "*.nc4", "*.netcdf" },
  callback = function(ev)
    require("config.hpc").ncview(ev.match)
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(ev.buf) then
        vim.cmd("silent! bwipeout " .. ev.buf)
      end
    end)
  end,
})

-- In Emacs's vterm, evil would take the keys (Escape first): tell Emacs
-- (emacs/modules/anthe-vterm.el) to send them all here while Neovim runs.
-- Over SSH, INSIDE_EMACS doesn't come along: say it there too, other
-- terminals ignore it. In tmux, tmux would swallow it.
local in_vterm = (vim.env.INSIDE_EMACS or ""):find("vterm")
  or (vim.env.SSH_TTY and not vim.env.TMUX)
if in_vterm then
  local function vterm_raw(on)
    pcall(vim.api.nvim_chan_send, vim.v.stderr, '\027]51;Eanthe/vterm-raw "' .. on .. '"\027\\')
  end
  vterm_raw("on")
  vim.api.nvim_create_autocmd("VimResume", { callback = function() vterm_raw("on") end })
  vim.api.nvim_create_autocmd({ "VimLeavePre", "VimSuspend" }, { callback = function() vterm_raw("off") end })
end
