--- @module targets
--- Action for Make targets

local M = {}
local fn = vim.fn
local api = vim.api
local log = vim.log.levels
local config = require("make.config")

--- Parse the top-level Makefile and return a list of target names.
--- Filters out duplicates and empty names.
---@return string[] targets
function M.parse_makefile()
	local path = fn.getcwd() .. "/Makefile"
	if fn.filereadable(path) == 0 then
		api.nvim_notify("No Makefile found in current directory", log.ERROR, {})
		return {}
	end

	local lines = fn.readfile(path)
	local seen, targets = {}, {}
	for _, line in ipairs(lines) do
    local name = line:match("^([%w%-%_]+)%s*:")
		if name and not seen[name] then
			table.insert(targets, name)
			seen[name] = true
		end
	end

	if config.debug then
		api.nvim_notify("Found targets: " .. table.concat(targets, ", "), log.DEBUG, {})
	end

	return targets
end

--- Prompt the user for a target and run `make <target>` in a terminal split
function M.run()
	local targets = M.parse_makefile()
	if vim.tbl_isempty(targets) then
		return
	end

	vim.ui.select(targets, { prompt = "Select Make target:" }, function(choice)
		if not choice or choice:match("^%s*$") then
			return
		end

		local target = vim.trim(choice)
		require("make.terminal").exec(target)
	end)
end

return M
