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

--- Execute `make <target>` silently via jobstart, populate quickfix on finish.
--- @function exec_silent
--- @tparam string target Make target name
--- @tparam table opts
function M.exec_silent(target, opts)
  opts = opts or {}
  local stdout_lines = {}
  local stderr_lines = {}

  if opts.debug then
    vim.notify("Silent exec: make " .. target, log.DEBUG)
  end

  fn.jobstart({ "make", target }, {
    cwd = fn.getcwd(),
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.list_extend(stdout_lines, data)
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.list_extend(stderr_lines, data)
      end
    end,
    on_exit = function(_, code)
      vim.schedule(function()
        local all_lines = vim.list_extend(vim.deepcopy(stdout_lines), stderr_lines)
        local qf_items = {}
        for _, line in ipairs(all_lines) do
          if line ~= "" then
            table.insert(qf_items, { text = line })
          end
        end
        fn.setqflist({}, "r", { title = "make " .. target, items = qf_items })
        vim.cmd("copen")
        if code == 0 then
          vim.notify("make " .. target .. " succeeded", log.INFO)
        else
          vim.notify("make " .. target .. " failed (exit " .. code .. ")", log.WARN)
        end
      end)
    end,
  })
end

--- Execute `make <target>` in a temporary terminal split that closes on finish.
--- @function exec_autoclose
--- @tparam string target Make target name
--- @tparam table opts
function M.exec_autoclose(target, opts)
  opts = opts or {}
  local height = opts.height or 5
  local cur_win = api.nvim_get_current_win()

  if opts.debug then
    vim.notify("Auto-close exec: make " .. target, log.DEBUG)
  end

  vim.cmd("botright split")
  api.nvim_win_set_height(0, height)
  local term_win = api.nvim_get_current_win()
  vim.cmd("terminal make " .. target)
  local term_buf = api.nvim_get_current_buf()

  api.nvim_create_autocmd("TermClose", {
    buffer = term_buf,
    once = true,
    callback = function()
      vim.schedule(function()
        if api.nvim_win_is_valid(term_win) then
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

  -- Return focus immediately to original window
  api.nvim_set_current_win(cur_win)
end

--- Execute `make <target>` in the persistent terminal.
--- Routes to exec_silent or exec_autoclose based on opts.
--- @function exec
--- @tparam string target Make target name
--- @tparam table opts   Passed to `ensure_terminal`
function M.exec(target, opts)
  opts = opts or {}

  if opts.silent then
    return M.exec_silent(target, opts)
  elseif opts.close_on_finish then
    return M.exec_autoclose(target, opts)
  end

  local cur_win = api.nvim_get_current_win()
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
  vim.cmd("stopinsert")

  -- Return focus to original window
  api.nvim_set_current_win(cur_win)
end

return M
