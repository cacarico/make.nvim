--- Functions to select and run Makefile targets using `vim.ui.select`.
--- @module 'make.targets'

local M     = {}
local utils = require("make.utils")
local term  = require("make.terminal")
local log   = vim.log.levels

--- Prompt user to select a Makefile target (names only) and run it.
---@param opts? table Forwarded to terminal.run (args/silent/close_on_finish/prompt_args)
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
    term.run(choice, opts)
  end)
end

--- Prompt user to select a Makefile target (with descriptions) and run it.
---@param opts? table Forwarded to terminal.run
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
    term.run(choice.name, opts)
  end)
end

return M
