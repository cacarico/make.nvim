--- Terminal management for make.nvim.
--- @module 'make.terminal'
local M   = {}
local api = vim.api
local fn  = vim.fn
local log = vim.log.levels

---@class MakeTermState
---@field buf integer|nil Terminal buffer handle
---@field win integer|nil Terminal window handle
local state = { buf = nil, win = nil }

--- Ensure the persistent make terminal exists and return its handles.
--- Opens a global-width bottom split using pure API. win = -1 means
--- a global split (full editor width), matching the old botright behaviour.
---@return MakeTermState
local function ensure_terminal()
  local cfg = require("make.config").values

  if state.win and api.nvim_win_is_valid(state.win) then
    return state
  end

  if not (state.buf and api.nvim_buf_is_valid(state.buf)) then
    state.buf = api.nvim_create_buf(false, true)
  end

  state.win = api.nvim_open_win(state.buf, true, {
    split  = "below",
    win    = -1,
    height = cfg.term_height,
  })

  if vim.bo[state.buf].buftype ~= "terminal" then
    vim.fn.jobstart(vim.o.shell, { term = true })
  end

  return state
end

--- Toggle visibility of the make terminal.
--- Height always comes from config; no per-call overrides.
function M.toggle()
  if state.win and api.nvim_win_is_valid(state.win) then
    api.nvim_win_hide(state.win)
  else
    ensure_terminal()
  end
end

--- Execute `make <target>` in the persistent terminal.
--- Single-purpose: persistent terminal only, no branching.
---@param target string Make target name
---@param opts? { debug?: boolean }
function M.exec(target, opts)
  opts = opts or {}
  local cur_win = api.nvim_get_current_win()
  local term = ensure_terminal()
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

  api.nvim_set_current_win(cur_win)
end

--- Execute `make <target>` silently via vim.system(), populate quickfix on finish.
---@param target string Make target name
---@param opts? { debug?: boolean }
function M.exec_silent(target, opts)
  opts = opts or {}

  if opts.debug then
    vim.notify("Silent exec: make " .. target, log.DEBUG)
  end

  vim.system({ "make", target }, { cwd = fn.getcwd(), text = true }, function(result)
    vim.schedule(function()
      local output = (result.stdout or "") .. (result.stderr or "")
      local lines = vim.split(output, "\n", { trimempty = true })
      local items = vim.tbl_map(function(l) return { text = l } end, lines)
      fn.setqflist({}, "r", { title = "make " .. target, items = items })
      vim.cmd("copen")
      if result.code == 0 then
        vim.notify("make " .. target .. " succeeded", log.INFO)
      else
        vim.notify("make " .. target .. " failed (exit " .. result.code .. ")", log.WARN)
      end
    end)
  end)
end

--- Execute `make <target>` in a temporary terminal split that auto-closes on finish.
---@param target string Make target name
---@param opts? { debug?: boolean }
function M.exec_autoclose(target, opts)
  opts = opts or {}
  local cfg = require("make.config").values
  local cur_win = api.nvim_get_current_win()

  if opts.debug then
    vim.notify("Auto-close exec: make " .. target, log.DEBUG)
  end

  local term_buf = api.nvim_create_buf(false, true)
  local term_win = api.nvim_open_win(term_buf, true, {
    split  = "below",
    win    = -1,
    height = cfg.term_height,
  })

  vim.fn.jobstart({ "make", target }, { term = true })

  api.nvim_create_autocmd("TermClose", {
    buffer = term_buf,
    once   = true,
    callback = function()
      vim.schedule(function()
        if api.nvim_win_is_valid(term_win) and #api.nvim_list_wins() > 1 then
          api.nvim_win_close(term_win, true)
        end
        if api.nvim_buf_is_valid(term_buf) then
          api.nvim_buf_delete(term_buf, { force = true })
        end
        if api.nvim_win_is_valid(cur_win) then
          api.nvim_set_current_win(cur_win)
        end
      end)
    end,
  })

  api.nvim_set_current_win(cur_win)
end

return M
