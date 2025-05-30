--- Terminal management for make.nvim.
--- @module 'make.terminal'
local M   = {}
local api = vim.api
local fn  = vim.fn
local log = vim.log.levels

--- Internal state for the persistent terminal.
--- @class state
--- @field buf number|nil Terminal buffer handle
--- @field win number|nil Terminal window handle
local state = { buf = nil, win = nil }

--- Ensure the make terminal exists and return its handles.
--- @tparam table opts
--- @tparam number opts.height Desired split height
--- @tparam boolean opts.debug   Whether to log debug info
--- @treturn table { buf = buffer, win = window }
local function ensure_terminal(opts)
  opts = opts or {}
  local height = opts.height or 5

  if state.win and api.nvim_win_is_valid(state.win) then
    return state
  end

  if not (state.buf and api.nvim_buf_is_valid(state.buf)) then
    state.buf = api.nvim_create_buf(false, true)
  end

  --- Open a bottom split and set height
  vim.cmd("botright split")
  api.nvim_win_set_height(0, height)
  local win = api.nvim_get_current_win()
  api.nvim_win_set_buf(win, state.buf)

  if vim.bo[state.buf].buftype ~= "terminal" then
    vim.cmd("terminal")
    vim.cmd("startinsert")
  end

  state.win = win

  if opts.debug then
    vim.notify("Opened make terminal (win " .. win .. ")", log.DEBUG)
  end

  return state
end

--- Toggle visibility of the make terminal.
--- @function toggle
--- @tparam table opts Same as `ensure_terminal` opts
function M.toggle(opts)
  opts = opts or {}
  if state.win and api.nvim_win_is_valid(state.win) then
    api.nvim_win_hide(state.win)
  else
    ensure_terminal(opts)
  end
end

--- Execute `make <target>` in the persistent terminal.
--- @function exec
--- @tparam string target Make target name
--- @tparam table opts   Passed to `ensure_terminal`
function M.exec(target, opts)
  opts = opts or {}
  local term = ensure_terminal(opts)
  local job  = vim.b[term.buf].terminal_job_id
  if not job then
    vim.notify("Terminal job not found", log.ERROR)
    return
  end

  if opts.debug then
    vim.notify("Executing: make " .. target, log.DEBUG)
  end

  fn.chansend(job, "clear\n")
  fn.chansend(job, "make " .. target .. "\n")

  --- Exit insert mode to allow normal-mode commands after run
  vim.cmd("stopinsert")
end

return M
