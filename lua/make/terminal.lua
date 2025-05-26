local M = {}

-- holds current terminal buffer & window
local state = { terminal = { buf = nil, win = nil } }

-- create or reuse the terminal split & buffer, enter terminal mode
local function ensure_terminal(opts)
  opts = opts or {}
  local height = opts.height or 5

  -- if we already have a valid window, just return it
  if state.terminal.win
     and type(state.terminal.win) == "number"
     and vim.api.nvim_win_is_valid(state.terminal.win)
  then
    return state.terminal
  end

  -- otherwise (re)create the buffer if needed
  if not (state.terminal.buf and vim.api.nvim_buf_is_valid(state.terminal.buf)) then
    state.terminal.buf = vim.api.nvim_create_buf(false, true)
  end

  -- open the split and resize
  vim.cmd(("belowright split | resize %d"):format(height))
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, state.terminal.buf)

  -- if not a terminal yet, start one
  if vim.bo[state.terminal.buf].buftype ~= "terminal" then
    vim.cmd("terminal")
    vim.cmd("startinsert")
  end

  state.terminal.win = win
  return state.terminal
end

--- Toggle the bottom terminal on/off
function M.toggle(opts)
  local valid = state.terminal.win
     and type(state.terminal.win) == "number"
     and vim.api.nvim_win_is_valid(state.terminal.win)

  if valid then
    vim.api.nvim_win_hide(state.terminal.win)
  else
    ensure_terminal(opts)
  end
end

--- Run `make <target>` in the terminal, creating it if needed
function M.exec(target, opts)
  local term = ensure_terminal(opts)

  local job_id = vim.b[term.buf].terminal_job_id
  assert(job_id, "No terminal job found!")
  vim.fn.chansend(job_id, "make " .. target .. "\n")
end

return M
