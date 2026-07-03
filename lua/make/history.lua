--- Run history for make.nvim (in-memory, persisted to stdpath('data')).
--- @module 'make.history'
local M = {}

local MAX = 100

---@class MakeHistoryEntry
---@field target string Make target name
---@field args string   Extra args passed to make ("" if none)
---@field mode string   "terminal" | "silent" | "autoclose"
---@field cwd string     Directory the run was launched from
---@field time integer   os.time() when the run was recorded

---@type MakeHistoryEntry[]
M.entries = {}
local loaded = false

local function history_path()
  return vim.fn.stdpath("data") .. "/make_nvim_history.json"
end

--- Load persisted history from disk (only once per session).
function M.load()
  if loaded then
    return
  end
  loaded = true
  local fd = io.open(history_path(), "r")
  if not fd then
    return
  end
  local content = fd:read("*a")
  fd:close()
  if not content or content == "" then
    return
  end
  local ok, data = pcall(vim.json.decode, content)
  if ok and type(data) == "table" then
    M.entries = data
  end
end

--- Persist history to disk.
function M.save()
  local ok, encoded = pcall(vim.json.encode, M.entries)
  if not ok then
    return
  end
  -- The data dir may not exist yet on a fresh install; create it.
  vim.fn.mkdir(vim.fn.stdpath("data"), "p")
  local fd = io.open(history_path(), "w")
  if not fd then
    return
  end
  fd:write(encoded)
  fd:close()
end

--- Record a run: newest first, de-duplicated, capped, persisted.
--- No-op when the `history` config option is disabled.
---@param entry { target: string, args?: string, mode?: string, cwd?: string }
function M.record(entry)
  if not require("make.config").values.history then
    return
  end
  M.load()
  local rec = {
    target = entry.target,
    args   = entry.args or "",
    mode   = entry.mode or "terminal",
    cwd    = entry.cwd or (vim.uv.cwd() or ""),
    time   = os.time(),
  }
  -- Drop an identical prior run so this one moves to the front.
  for i = #M.entries, 1, -1 do
    local e = M.entries[i]
    if e.target == rec.target and (e.args or "") == rec.args
      and e.cwd == rec.cwd and e.mode == rec.mode then
      table.remove(M.entries, i)
    end
  end
  table.insert(M.entries, 1, rec)
  while #M.entries > MAX do
    table.remove(M.entries)
  end
  M.save()
end

--- All history entries, newest first.
---@return MakeHistoryEntry[]
function M.list()
  M.load()
  return M.entries
end

--- Most recent entry, or nil.
---@return MakeHistoryEntry|nil
function M.last()
  M.load()
  return M.entries[1]
end

--- Re-run a history entry in its original mode.
---@param entry MakeHistoryEntry
function M.rerun(entry)
  require("make.terminal").run(entry.target, {
    args            = entry.args or "",
    silent          = entry.mode == "silent",
    close_on_finish = entry.mode == "autoclose",
  })
end

--- Re-run the most recent make invocation.
function M.run_last()
  local e = M.last()
  if not e then
    vim.notify("make.nvim: no previous run", vim.log.levels.WARN)
    return
  end
  M.rerun(e)
end

--- Pick a past run via vim.ui.select (telescope-compatible) and re-run it.
function M.pick()
  local entries = M.list()
  if vim.tbl_isempty(entries) then
    vim.notify("make.nvim: history is empty", vim.log.levels.INFO)
    return
  end
  vim.ui.select(entries, {
    prompt = "Make history",
    format_item = function(e)
      local when = os.date("%Y-%m-%d %H:%M", e.time or 0)
      local cmd = "make " .. e.target .. (e.args ~= "" and (" " .. e.args) or "")
      return string.format("%-40s [%s]  %s", cmd, e.mode or "terminal", when)
    end,
  }, function(choice)
    if not choice then
      return
    end
    M.rerun(choice)
  end)
end

return M
