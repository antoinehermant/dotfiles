-- Keys, after LazyVim's: Doom's where I have them in Emacs (SPC is the leader)
local map = vim.keymap.set
local hpc = function(name, ...)
  local args = { ... }
  return function()
    require("config.hpc")[name](unpack(args))
  end
end

-- Files and buffers
map("n", "<leader>.", function() require("config.find_file").open() end, { desc = "Find file (Tab: into a folder, Enter: open it in oil)" })
map("n", "<leader>bs", "<cmd>write<cr>", { desc = "Save buffer" })
map("n", "<leader>fs", "<cmd>write<cr>", { desc = "Save file" })
map("n", "<leader>bk", function() Snacks.bufdelete() end, { desc = "Kill buffer" })
map("n", "<leader>bb", function() Snacks.picker.buffers() end, { desc = "Switch buffer" })
map("n", "<leader>fr", function() Snacks.picker.recent() end, { desc = "Recent files" })
map("n", "<leader>-", "<cmd>Oil<cr>", { desc = "Folder of this file (oil)" })

-- Search
map("n", "<leader>ss", function() Snacks.picker.lines() end, { desc = "Search this buffer" })
map("n", "<leader>sp", function() Snacks.picker.grep() end, { desc = "Search the project" })
map("n", "<leader>pp", function() Snacks.picker.projects() end, { desc = "Switch project" })

-- Open: the terminal in a popup below, as vterm (SPC o t), here or at the project's root
map("n", "<leader>ot", function() Snacks.terminal.toggle(nil, { cwd = vim.fn.expand("%:p:h") }) end, { desc = "Terminal here" })
map("n", "<leader>oT", function() Snacks.terminal.toggle(nil, { cwd = LazyVim.root() }) end, { desc = "Terminal at the root" })

-- Git: magit's clone
map("n", "<leader>gg", "<cmd>Neogit<cr>", { desc = "Neogit (magit)" })

-- Slurm, as in Emacs (anthe-slurm.el)
map("n", "<leader>kqb", hpc("sbatch"), { desc = "Submit this file (sbatch)" })
map("n", "<leader>kqq", hpc("squeue", "q"), { desc = "My queue" })
map("n", "<leader>kqg", hpc("squeue", "g"), { desc = "The group's queue" })

-- Windows, as Doom's SPC w (LazyVim has them too)
map("n", "<leader>wv", "<C-w>v", { desc = "Split right" })
map("n", "<leader>ws", "<C-w>s", { desc = "Split below" })
map("n", "<leader>wd", "<C-w>c", { desc = "Close window" })
