return {
  -- Telescope (with file browser and hidden files)
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",  -- Use a stable branch
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-file-browser.nvim",
    },
    config = function()
      -- Load telescope-file-browser extension
      require("telescope").load_extension("file_browser")

      -- Configure telescope defaults
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")
      local action_utils = require("telescope.actions.utils")

      require("telescope").setup({
        defaults = {
          -- Show hidden files (e.g., .config)
          file_ignore_patterns = {},
          mappings = {
            i = {
              -- Use <Tab> to autocomplete the current candidate's name
              ["<Tab>"] = function(prompt_bufnr)
                local current_picker = action_state.get_current_picker(prompt_bufnr)
                local current_entry = action_state.get_selected_entry()
                if current_entry then
                  -- Insert the selected entry's filename into the prompt
                  local current_line = action_state.get_current_line()
                  local entry_path = current_entry.value
                  local entry_name = vim.fn.fnamemodify(entry_path, ":t")
                  -- Replace the current line with the autocompleted filename
                  action_state.get_current_picker(prompt_bufnr):reset_prompt(vim.fn.fnamemodify(current_line, ":h") .. "/" .. entry_name)
                else
                  -- If no entry is selected, move to the next one
                  actions.move_selection_next(prompt_bufnr)
                end
              end,
              -- Use <C-j> to move down
              ["<C-j>"] = actions.move_selection_next,
              -- Use <C-k> to move up
              ["<C-k>"] = actions.move_selection_previous,
            },
          },
        },
      })
    end,
  },
}
