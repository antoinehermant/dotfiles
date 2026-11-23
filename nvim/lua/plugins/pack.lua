-- With $NVIM_LOCAL (UBELIX), after installing or updating plugins, pack
-- them again into the archive in the home (bin/nvim-plugins pack), which a
-- new login node unpacks
if not vim.env.NVIM_LOCAL then
  return {}
end
vim.api.nvim_create_autocmd("User", {
  pattern = { "LazyInstall", "LazyUpdate", "LazySync", "LazyClean" },
  callback = function()
    local script = vim.fn.expand("~/.dotfiles/bin/nvim-plugins")
    if vim.fn.executable(script) == 1 then
      vim.fn.jobstart({ script, "pack" }, { detach = true })
      vim.notify("Packing the plugins for the next login node")
    end
  end,
})
return {}
