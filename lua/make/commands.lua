-- lua/make_targets.lua

local M = {}
local api = vim.api
local fn  = vim.fn
local log = vim.log.levels

---
-- Parse the top-level Makefile and return a list of target names
-- Filters out duplicates and empty names.
function M.parse_makefile()
  local cwd  = fn.getcwd()
  local path = cwd .. '/Makefile'
  if fn.filereadable(path) == 0 then
    api.nvim_notify('No Makefile found in ' .. cwd, log.ERROR)
    return {}
  end

  local lines   = fn.readfile(path)
  local targets = {}
  for _, line in ipairs(lines) do
    -- Match "target:" at start of line
    local name = line:match('^([%w%-%_]+)%s*:')
    if name and name ~= '' and not vim.tbl_contains(targets, name) then
      table.insert(targets, name)
    end
  end
  return targets
end

---
-- Prompt the user for a target and run `make <target>` in a terminal split
function M.run()
  local targets = M.parse_makefile()
  if vim.tbl_isempty(targets) then
    return
  end

  vim.ui.select(targets, { prompt = 'Select Make target:' }, function(choice)
    -- Abort if user cancelled or selected an empty string
    if not choice or choice:match('^%s*$') then
      return
    end

    -- Trim whitespace from the choice
    local target = choice:match('^%s*(.-)%s*$')
    print(target)

  end)
end

return M
