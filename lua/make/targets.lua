--- Functions to select and run Makefile targets using `vim.ui.select`.
--- @module 'make.targets'
---

local M = {}
local utils = require("make.utils")
local term = require("make.terminal")
local log = vim.log.levels
local config = require("make").config

--- Prompt user to select a Makefile target (names only) and execute it.
--- Uses `vim.ui.select` to present the list of target names.
--- @function run
function M.run()
	local targets = utils.parse_makefile()
	if vim.tbl_isempty(targets) then
		return
	end

	-- Extract just the names for the picker
	local names = vim.tbl_map(function(t)
		return t.name
	end, targets)

	vim.ui.select(names, { prompt = "Make targets" }, function(choice)
		if not choice or choice == "" then
			return
		end
		if config.debug then
			vim.notify("Selected target: " .. choice, log.DEBUG)
		end
		term.exec(choice)
	end)
end

--- Prompt user to select a Makefile target (with descriptions) and execute it.
--- Uses `vim.ui.select` with a custom `format_item` to show `name: desc`.
--- @function run_description
function M.run_description()
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
		if config.debug then
			vim.notify("Selected target: " .. choice.name, log.DEBUG)
		end
		term.exec(choice.name)
	end)
end

return M
