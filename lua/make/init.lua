--- Main entrypoint for the make.nvim plugin.
--- @module 'make'
local M = {}

--- Default plugin configuration.
--- @class config
--- @field debug boolean Whether to enable debug notifications (default: `false`)
--- @field term_height number Height of the make terminal split (default: `5`)
--- @field use_default_keymaps boolean Whether to set up default `<leader>` mappings (default: `true`)
M.config = {
  debug = false,
  term_height = 5,
  use_default_keymaps = true,
}

--- Set up the plugin with user-provided options.
--- Merges `opts` into `M.config`, defines commands and (optionally) keymaps.
--- @tparam table opts Plugin options to override defaults
--- @usage
--- require('make').setup {
---   debug = true,
---   term_height = 10,
---   use_default_keymaps = false,
--- }
function M.setup(opts)
  opts = opts or {}
  --- Merge user options into default config
  for k, v in pairs(opts) do
    if M.config[k] ~= nil then
      M.config[k] = v
    end
  end

  --- Define default keymaps if enabled
  if M.config.use_default_keymaps then
    local safe_map = require("make.utils").safe_map
    safe_map("n", "<leader>tm", M.toggle, { desc = "Toggle Make terminal" })
    safe_map("n", "<leader>mt", M.run,    { desc = "Make: Select target" })
    safe_map("n", "<leader>md", M.run_desc, { desc = "Make: Select target (with desc)" })
  end

  --- Create user commands
  vim.api.nvim_create_user_command("MakeToggle", M.toggle, { nargs = 0 })
  vim.api.nvim_create_user_command("MakeRun", M.run, { nargs = 0 })
  vim.api.nvim_create_user_command("MakeRunDescription", M.run_desc, { nargs = 0 })
  vim.api.nvim_create_user_command("MakeRunTelescope", M.telescope, { nargs = 0 })
  vim.api.nvim_create_user_command("MakeRunTelescopeDescription", M.telescope_desc, { nargs = 0 })
end

--- Toggle the make terminal split open or closed.
--- @function toggle
--- @see make.terminal.toggle
function M.toggle()
  require("make.terminal").toggle {
    height = M.config.term_height,
    debug  = M.config.debug,
  }
end

--- Prompt for a target and run `make <target>` in terminal.
--- @function run
--- @see make.targets.run
function M.run()
  require("make.targets").run()
end

--- Prompt for a target (with descriptions) and run it.
--- @function run_desc
--- @see make.targets.run_description
function M.run_desc()
  require("make.targets").run_description()
end

--- Use Telescope picker for targets and run the selected one.
--- @function telescope
--- @see make.telescope.run
function M.telescope()
  require("make.telescope").run()
end

--- Telescope picker with target descriptions.
--- @function telescope_desc
--- @see make.telescope.run_description
function M.telescope_desc()
  require("make.telescope").run_description()
end

return M
