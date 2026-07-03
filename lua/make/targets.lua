--- Functions to select and run Makefile targets using `vim.ui.select`.
--- @module 'make.targets'

local M     = {}
local utils = require("make.utils")
local term  = require("make.terminal")
local log   = vim.log.levels

--- Dispatch to the correct terminal function based on opts.
---@param target string
---@param opts? table
local function exec(target, opts)
  local cfg = require("make.config").values
  opts = opts or {}

  -- Per-call opts win; fall back to config defaults when unset.
  local silent = opts.silent
  if silent == nil then silent = cfg.silent end
  local close = opts.close_on_finish
  if close == nil then close = cfg.close_on_finish end

  if silent then
    term.exec_silent(target, opts)
  elseif close then
    term.exec_autoclose(target, opts)
  else
    term.exec(target, opts)
  end
end

--- Prompt user to select a Makefile target (names only) and execute it.
---@param opts? table Forwarded to terminal exec functions
function M.run(opts)
  local targets = utils.parse_makefile()
  if vim.tbl_isempty(targets) then
    return
  end

  local names = vim.tbl_map(function(t)
    return t.name
  end, targets)

  vim.ui.select(names, { prompt = "Make targets" }, function(choice)
    if not choice or choice == "" then
      return
    end
    if require("make.config").values.debug then
      vim.notify("Selected target: " .. choice, log.DEBUG)
    end
    exec(choice, opts)
  end)
end

--- Prompt user to select a Makefile target (with descriptions) and execute it.
---@param opts? table Forwarded to terminal exec functions
function M.run_description(opts)
  local targets = utils.parse_makefile()
  if vim.tbl_isempty(targets) then
    return
  end

  vim.ui.select(targets, {
    prompt = "Make targets (with description)",
    format_item = function(item)
      return item.name .. (item.desc ~= "" and ": " .. item.desc or "")
    end,
  }, function(choice)
    if not choice or not choice.name then
      return
    end
    if require("make.config").values.debug then
      vim.notify("Selected target: " .. choice.name, log.DEBUG)
    end
    exec(choice.name, opts)
  end)
end

return M
