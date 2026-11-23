-- UBELIX from Neovim, as Emacs's anthe-slurm.el and openwith: ncview for
-- NetCDF files, sbatch, and the Slurm queue in a window that reloads.
local M = {}

-- The X display of the latest SSH connection: in tmux, a shell or Neovim
-- started before keeps the one of the connection it was started from
local function display()
  if vim.env.TMUX then
    local line = vim.fn.system({ "tmux", "show-environment", "DISPLAY" })
    local value = line:match("^DISPLAY=(%S+)")
    if value then
      return value
    end
  end
  return vim.env.DISPLAY
end

--- FILE in ncview, in its own window (needs X forwarding: ssh -X)
function M.ncview(file)
  local env = { DISPLAY = display() }
  if not env.DISPLAY then
    vim.notify("No X display: connect with X forwarding (ssh -X) to see " .. file, vim.log.levels.WARN)
    return
  end
  if vim.fn.executable("ncview") == 0 then
    vim.notify("No ncview: module load nctools (hpc-session loads it)", vim.log.levels.WARN)
    return
  end
  vim.fn.jobstart({ "ncview", file }, { env = env, detach = true })
  vim.notify("ncview " .. vim.fn.fnamemodify(file, ":t"))
end

--- Submit the file of the buffer with sbatch
function M.sbatch()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    return vim.notify("No file to submit", vim.log.levels.WARN)
  end
  vim.cmd("silent! write")
  local out = vim.fn.system({ "sbatch", file })
  vim.notify(vim.trim(out), vim.v.shell_error == 0 and vim.log.levels.INFO or vim.log.levels.ERROR)
end

-- The queue's commands, from ~/.squeue_commands.json, as in Emacs:
-- {"q": "squeue -u $USER", "g": "squeue -A ..."}
local function squeue_command(which)
  local ok, lines = pcall(vim.fn.readfile, vim.fn.expand("~/.squeue_commands.json"))
  if ok then
    local decoded = vim.json.decode(table.concat(lines, "\n"))
    if decoded and decoded[which] then
      return decoded[which]
    end
  end
  return "squeue -u $USER"
end

local queue = { buf = nil, timer = nil, command = nil }

local function refresh()
  if not (queue.buf and vim.api.nvim_buf_is_valid(queue.buf)) or vim.fn.bufwinid(queue.buf) == -1 then
    -- Hidden: stop polling
    if queue.timer then
      queue.timer:stop()
      queue.timer = nil
    end
    return
  end
  vim.system({ "bash", "-c", queue.command }, { text = true }, function(result)
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(queue.buf) then
        return
      end
      local lines = vim.split(result.stdout or "", "\n", { trimempty = true })
      vim.bo[queue.buf].modifiable = true
      vim.api.nvim_buf_set_lines(queue.buf, 0, -1, false, lines)
      vim.bo[queue.buf].modifiable = false
      local win = vim.fn.bufwinid(queue.buf)
      if win ~= -1 then
        vim.api.nvim_win_set_height(win, math.max(3, math.min(#lines + 1, math.floor(vim.o.lines * 0.25))))
      end
    end)
  end)
end

--- The queue (WHICH: "q" mine, "g" the group's) below, reloaded every second
--- while it shows; again closes it. `r' in it stops or restarts reloading.
function M.squeue(which)
  local win = queue.buf and vim.fn.bufwinid(queue.buf) or -1
  if win ~= -1 then
    vim.api.nvim_win_close(win, true)
    return
  end
  if not (queue.buf and vim.api.nvim_buf_is_valid(queue.buf)) then
    queue.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(queue.buf, "slurm-squeue")
    vim.bo[queue.buf].filetype = "squeue"
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = queue.buf, desc = "Close" })
    vim.keymap.set("n", "r", function()
      if queue.timer then
        queue.timer:stop()
        queue.timer = nil
        vim.notify("Slurm queue: reloading off")
      else
        M.start_timer()
        vim.notify("Slurm queue: reloading every second")
      end
    end, { buffer = queue.buf, desc = "Reload on/off" })
  end
  queue.command = squeue_command(which)
  vim.cmd("botright split")
  vim.api.nvim_win_set_buf(0, queue.buf)
  vim.wo.number, vim.wo.relativenumber, vim.wo.wrap = false, false, false
  vim.cmd("wincmd p")
  M.start_timer()
end

function M.start_timer()
  if queue.timer then
    queue.timer:stop()
  end
  queue.timer = vim.uv.new_timer()
  queue.timer:start(0, 1000, vim.schedule_wrap(refresh))
end

return M
