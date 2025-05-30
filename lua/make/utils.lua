--- Utility functions for make.nvim.
--- @module 'make.utils'
local M = {}
local fn = vim.fn
local log = vim.log.levels

--- Parse the nearest Makefile and extract targets.
--- Searches cwd first, then upward (Neovim 0.9+).
--- Captures lines like `target: … ## description` or bare `target:`.
--- @treturn { name: string, desc: string }[] List of targets
function M.parse_makefile()
	local cwd = vim.loop.cwd() or fn.getcwd()
	local path = cwd .. "/Makefile"
	if fn.filereadable(path) == 0 and fn.has("nvim-0.9") == 1 then
		--- Attempt to find Makefile upward
		local found = vim.fs.find("Makefile", { path = cwd, upward = true })
		path = (found and found[1]) or ""
	end
	if path == "" or fn.filereadable(path) == 0 then
		vim.notify("No Makefile found", log.ERROR)
		return {}
	end

	local lines = fn.readfile(path)
	local seen = {}
	local out = {}

	for _, line in ipairs(lines) do
		local name, desc = line:match("^([%w%-%_]+)%s*:%s*.-##%s*(.+)$")
		if name and not seen[name] then
			table.insert(out, { name = name, desc = desc })
			seen[name] = true
		elseif not name then
			name = line:match("^([%w%-%_]+)%s*:")
			if name and not seen[name] then
				table.insert(out, { name = name, desc = "" })
				seen[name] = true
			end
		end
	end

	if require("make").config.debug then
		--- Log parsed targets in debug mode
		local list = {}
		for _, t in ipairs(out) do
			table.insert(list, t.name .. (t.desc ~= "" and ": " .. t.desc or ""))
		end
		vim.notify("Parsed targets: " .. table.concat(list, ", "), log.DEBUG)
	end

	return out
end

--- Safely map a key if no existing mapping is found.
--- @tparam string mode Vim mode (e.g. `"n"`, `"i"`)
--- @tparam string lhs  Left-hand side of the mapping
--- @tparam function|string rhs Right-hand side (command or Lua fn)
--- @tparam table opts  Mapping options
function M.safe_map(mode, lhs, rhs, opts)
	opts = opts or {}
	local existing = vim.fn.maparg(lhs, mode, false, false)
	if existing == "" then
		vim.keymap.set(mode, lhs, rhs, opts)
	end
end

return M
