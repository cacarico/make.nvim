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

--- User-facing notification, gated by the `notify` config option.
---@param msg string
---@param level? integer
local function notify_user(msg, level)
  if require("make.config").values.notify then
    vim.notify(msg, level or log.INFO)
  end
end

--- Split an args string into argv tokens, honouring single/double quotes
--- (e.g. `CFLAGS="-O2 -g"` stays a single token). Backslash escaping is not
--- handled; for full shell semantics use the persistent terminal, which sends
--- the raw string to the shell.
---@param args? string
---@return string[]
function M.split_args(args)
  if not args or args == "" then
    return {}
  end
  local out, buf, quote, has = {}, {}, nil, false
  for i = 1, #args do
    local c = args:sub(i, i)
    if quote then
      if c == quote then
        quote = nil
      else
        buf[#buf + 1] = c
      end
    elseif c == '"' or c == "'" then
      quote = c
      has = true
    elseif c:match("%s") then
      if has then
        out[#out + 1] = table.concat(buf)
        buf, has = {}, false
      end
    else
      buf[#buf + 1] = c
      has = true
    end
  end
  if has then
    out[#out + 1] = table.concat(buf)
  end
  return out
end

--- Human-readable "make <target> <args>" string.
---@param target string
---@param args? string
---@return string
local function cmd_display(target, args)
  if args and args ~= "" then
    return "make " .. target .. " " .. args
  end
  return "make " .. target
end

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
    -- Only hide when another window exists; hiding the last window throws E444.
    if #api.nvim_list_wins() > 1 then
      api.nvim_win_hide(state.win)
    end
  else
    ensure_terminal()
  end
end

--- Run `make <target> <args>` in the persistent terminal (interactive shell).
--- Completion is not detectable here, so only a start notification is emitted.
---@param target string Make target name
---@param opts? { args?: string, debug?: boolean }
function M.exec(target, opts)
  opts = opts or {}
  local cur_win = api.nvim_get_current_win()
  local term = ensure_terminal()
  local job  = vim.b[term.buf].terminal_job_id

  if not job then
    vim.notify("Terminal job not found", log.ERROR)
    return
  end

  local display = cmd_display(target, opts.args)
  if opts.debug then
    vim.notify("Executing: " .. display, log.DEBUG)
  end
  notify_user("Running: " .. display)

  fn.chansend(job, "clear\n")
  fn.chansend(job, display .. "\n")

  api.nvim_set_current_win(cur_win)
end

--- Run `make <target> <args>` silently via vim.system(); output to quickfix.
---@param target string Make target name
---@param opts? { args?: string, debug?: boolean }
function M.exec_silent(target, opts)
  opts = opts or {}
  local display = cmd_display(target, opts.args)

  if opts.debug then
    vim.notify("Silent exec: " .. display, log.DEBUG)
  end
  notify_user("Running: " .. display)

  local argv = { "make", target }
  vim.list_extend(argv, M.split_args(opts.args))

  vim.system(argv, { cwd = fn.getcwd(), text = true }, function(result)
    vim.schedule(function()
      local output = (result.stdout or "") .. (result.stderr or "")
      local lines = vim.split(output, "\n", { trimempty = true })
      local items = vim.tbl_map(function(l) return { text = l } end, lines)
      fn.setqflist({}, "r", { title = display, items = items })
      vim.cmd("copen")
      if result.code == 0 then
        notify_user(display .. " succeeded", log.INFO)
      else
        notify_user(display .. " failed (exit " .. result.code .. ")", log.WARN)
      end
    end)
  end)
end

--- Run `make <target> <args>` in a temporary terminal split that auto-closes on finish.
---@param target string Make target name
---@param opts? { args?: string, debug?: boolean }
function M.exec_autoclose(target, opts)
  opts = opts or {}
  local cfg = require("make.config").values
  local cur_win = api.nvim_get_current_win()
  local display = cmd_display(target, opts.args)

  if opts.debug then
    vim.notify("Auto-close exec: " .. display, log.DEBUG)
  end
  notify_user("Running: " .. display)

  local term_buf = api.nvim_create_buf(false, true)
  local term_win = api.nvim_open_win(term_buf, true, {
    split  = "below",
    win    = -1,
    height = cfg.term_height,
  })

  local argv = { "make", target }
  vim.list_extend(argv, M.split_args(opts.args))
  vim.fn.jobstart(argv, { term = true })

  api.nvim_create_autocmd("TermClose", {
    buffer = term_buf,
    once   = true,
    callback = function()
      local status = vim.v.event.status
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
        if status == 0 then
          notify_user(display .. " succeeded", log.INFO)
        else
          notify_user(display .. " failed (exit " .. tostring(status) .. ")", log.WARN)
        end
      end)
    end,
  })

  api.nvim_set_current_win(cur_win)
end

--- Central entry point: optionally prompt for args, record history, dispatch by mode.
--- Used by the pickers, the `:Make` command and history re-runs.
---@param target string Make target name
---@param opts? { args?: string, silent?: boolean, close_on_finish?: boolean, prompt_args?: boolean, debug?: boolean }
function M.run(target, opts)
  opts = opts or {}

  -- Optionally prompt for extra make args before running.
  if opts.prompt_args and opts.args == nil then
    vim.ui.input({ prompt = "make " .. target .. " args: " }, function(input)
      if input == nil then
        return -- cancelled
      end
      M.run(target, vim.tbl_extend("force", opts, { args = input, prompt_args = false }))
    end)
    return
  end

  local cfg = require("make.config").values
  local silent = opts.silent
  if silent == nil then silent = cfg.silent end
  local close = opts.close_on_finish
  if close == nil then close = cfg.close_on_finish end

  local mode = silent and "silent" or (close and "autoclose" or "terminal")
  require("make.history").record({
    target = target,
    args   = opts.args or "",
    mode   = mode,
    cwd    = vim.fn.getcwd(),
  })

  if silent then
    M.exec_silent(target, opts)
  elseif close then
    M.exec_autoclose(target, opts)
  else
    M.exec(target, opts)
  end
end

return M
