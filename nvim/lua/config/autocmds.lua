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
