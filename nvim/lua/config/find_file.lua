-- SPC .: find a file as Doom's find-file, starting from the folder of the
-- buffer (oil's folder in oil). Typing filters; Tab goes into a folder
-- (Backspace, on an empty prompt, back up); Enter opens a file, or a folder
-- in oil; ~ goes home. Telescope's file browser.
local M = {}

local function start_dir()
  local ok, oil = pcall(require, "oil")
  local dir = ok and oil.get_current_dir() or nil
  if dir then
    return dir
  end
  local file = vim.api.nvim_buf_get_name(0)
  if file ~= "" and vim.fn.filereadable(file) == 1 then
    return vim.fn.fnamemodify(file, ":p:h")
  end
  return vim.fn.getcwd()
end

function M.open()
  local telescope = require("telescope")
  local actions = require("telescope.actions")
  local state = require("telescope.actions.state")
  local fb = telescope.extensions.file_browser
  local fb_actions = fb.actions

  local function into_or_open(prompt_bufnr)
    local entry = state.get_selected_entry()
    if not entry then
      return
    end
    if entry.Path and entry.Path:is_dir() then
      fb_actions.open_dir(prompt_bufnr, nil, entry.Path:absolute())
    else
      actions.select_default(prompt_bufnr)
    end
  end

  local function open_in_oil_or_file(prompt_bufnr)
    local entry = state.get_selected_entry()
    if entry and entry.Path and entry.Path:is_dir() then
      local dir = entry.Path:absolute()
      actions.close(prompt_bufnr)
      require("oil").open(dir)
    else
      actions.select_default(prompt_bufnr)
    end
  end

  fb.file_browser({
    path = start_dir(),
    cwd_to_path = true,
    hidden = { file_browser = true, folder_browser = true },
    grouped = true,
    respect_gitignore = false,
    prompt_path = true,
    hijack_netrw = false,
    initial_mode = "insert",
    attach_mappings = function(_, map)
      map("i", "<Tab>", into_or_open)
      map("i", "<CR>", open_in_oil_or_file)
      map("i", "~", fb_actions.goto_home_dir)
      map("i", "<C-j>", actions.move_selection_next)
      map("i", "<C-k>", actions.move_selection_previous)
      return true
    end,
  })
end

return M
