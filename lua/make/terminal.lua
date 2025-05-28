-- terminal.lua
--- @module terminal
--- Embedded terminal integration for Make targets

local M = {}
local log = vim.log.levels
local api = vim.api
local fn = vim.fn
local config = require("make.config")

local state = {
  terminal = {
    buf = nil,
    win = nil,
  },
}

--- Ensure a bottom split terminal is ready
---@param opts? table optional config
---@return table terminal state with buf and win
local function ensure_terminal(opts)
  opts = opts or {}
  local height = opts.height or 5

  if state.terminal.win and api.nvim_win_is_valid(state.terminal.win) then
    return state.terminal
  end

  if not (state.terminal.buf and api.nvim_buf_is_valid(state.terminal.buf)) then
    state.terminal.buf = api.nvim_create_buf(false, true)
  end

  vim.cmd("botright split")
  api.nvim_win_set_height(0, height)
  local win = api.nvim_get_current_win()
  api.nvim_win_set_buf(win, state.terminal.buf)

  if vim.bo[state.terminal.buf].buftype ~= "terminal" then
    vim.cmd("terminal")
    vim.cmd("startinsert")
  end

  state.terminal.win = win

  if config.debug then
    vim.notify("Terminal initialized in window " .. win, log.DEBUG)
  end

  return state.terminal
end

--- Toggle visibility of the terminal window
---@param opts? table optional config
function M.toggle(opts)
  if state.terminal.win and api.nvim_win_is_valid(state.terminal.win) then
    api.nvim_win_hide(state.terminal.win)
  else
    ensure_terminal(opts)
  end
end

--- Run `make <target>` in terminal and scroll output
---@param target string Make target to execute
---@param opts? table optional config
function M.exec(target, opts)
  local term = ensure_terminal(opts)
  local job_id = vim.b[term.buf].terminal_job_id
  assert(job_id, "No terminal job found!")

  if config.debug then
    vim.notify("Running make: " .. target, log.DEBUG)
  end

  fn.chansend(job_id, "make " .. target .. "\n")

  api.nvim_win_call(term.win, function()
  end)
end

return M
