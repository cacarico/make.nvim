--- Configuration for make.nvim.
--- @module 'make.config'

---@class MakeConfig
---@field debug boolean Whether to enable debug notifications
---@field term_height number Height of the make terminal split
---@field use_default_keymaps boolean Whether to set up default keymaps
---@field silent boolean Run targets without a terminal; output goes to quickfix
---@field close_on_finish boolean Auto-close terminal split when make exits
---@field notify boolean Show vim.notify messages when running/finishing targets
---@field history boolean Record run history and persist it across sessions

local M = {}

M.defaults = {
  debug               = false,
  term_height         = 5,
  use_default_keymaps = true,
  silent              = false,
  close_on_finish     = false,
  notify              = true,
  history             = true,
}

---@type MakeConfig
M.values = {}

---@param opts? MakeConfig
function M.setup(opts)
  M.values = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

-- Initialise with defaults so M.values is never empty before setup() is called
M.setup()

return M
