--- Main entrypoint for the make.nvim plugin.
--- @module 'make'
local M = {}

-- Lazy-load public functions via metatable (folke pattern).
-- fns is constructed once, not rebuilt per __index call.
-- Metatable must be installed BEFORE M.setup() is defined so that
-- M.toggle, M.run_desc, etc. resolve via __index when referenced inside setup().
local fns = {
  toggle         = function() require("make.terminal").toggle() end,
  run            = function(o) require("make.targets").run(o) end,
  run_desc       = function(o) require("make.targets").run_description(o) end,
  telescope      = function(o) require("make.telescope").run(nil, o) end,
  telescope_desc = function(o) require("make.telescope").run_description(nil, o) end,
}
setmetatable(M, { __index = fns })

--- Set up the plugin with user-provided options.
--- Merges `opts` into config, defines commands and (optionally) keymaps.
---@param opts? MakeConfig
function M.setup(opts)
  local cfg = require("make.config")
  cfg.setup(opts)

  if cfg.values.use_default_keymaps then
    local safe_map = require("make.utils").safe_map
    safe_map("t", "<esc><esc>", "<c-\\><c-n>")
    safe_map("n", "<leader>tm", M.toggle,   { desc = "Toggle Make terminal" })
    safe_map("n", "<leader>mt", M.run_desc, { desc = "Make: Select target (with desc)" })
  end

  vim.api.nvim_create_user_command("MakeToggle",                  M.toggle,         { nargs = 0 })
  vim.api.nvim_create_user_command("MakeRun",                     M.run,            { nargs = 0 })
  vim.api.nvim_create_user_command("MakeRunDescription",          M.run_desc,       { nargs = 0 })
  vim.api.nvim_create_user_command("MakeRunTelescope",            M.telescope,      { nargs = 0 })
  vim.api.nvim_create_user_command("MakeRunTelescopeDescription", M.telescope_desc, { nargs = 0 })
  vim.api.nvim_create_user_command("MakeRunSilent",
    function() M.run({ silent = true }) end, { nargs = 0 })
  vim.api.nvim_create_user_command("MakeRunSilentDescription",
    function() M.run_desc({ silent = true }) end, { nargs = 0 })
  vim.api.nvim_create_user_command("MakeRunClose",
    function() M.run({ close_on_finish = true }) end, { nargs = 0 })
  vim.api.nvim_create_user_command("MakeRunCloseDescription",
    function() M.run_desc({ close_on_finish = true }) end, { nargs = 0 })

  -- Pick a target (with descriptions), then prompt for extra make args.
  vim.api.nvim_create_user_command("MakeArgs",
    function() require("make.targets").run_description({ prompt_args = true }) end, { nargs = 0 })

  -- Free-form: :Make [target] [args...]. With no target it opens the picker.
  -- Completes target names for the first argument.
  vim.api.nvim_create_user_command("Make", function(info)
    local target = info.fargs[1]
    if not target then
      M.run(info)
      return
    end
    local args = table.concat(vim.list_slice(info.fargs, 2), " ")
    require("make.terminal").run(target, { args = args })
  end, {
    nargs = "*",
    complete = function(arglead, cmdline)
      -- Only complete the target (the first argument).
      local before = cmdline:sub(1, #cmdline - #arglead)
      if before:gsub("^%s*%S+%s*", "") ~= "" then
        return {}
      end
      local out = {}
      for _, t in ipairs(require("make.utils").parse_makefile()) do
        if t.name:find(arglead, 1, true) == 1 then
          table.insert(out, t.name)
        end
      end
      return out
    end,
  })

  -- History.
  vim.api.nvim_create_user_command("MakeHistory",
    function() require("make.history").pick() end, { nargs = 0 })
  vim.api.nvim_create_user_command("MakeAgain",
    function() require("make.history").run_last() end, { nargs = 0 })
end

return M
