---  Map a keymap if if they’re not already mapped
---@param mode string Vim mode
---@param lhs string Left-hand-side parameter
---@param rhs any Right-hand-side parametery
---@param opts any Extra options (eg. {desc = "Description"})
local function safe_map(mode, lhs, rhs, opts)
  opts = opts or {}
  -- pcall prevents an error if there's no mapping
  local ok, _ = pcall(vim.keymap.get, mode, lhs)
  if not ok then
    vim.keymap.set(mode, lhs, rhs, opts)
  end
end

safe_map("t", "<esc><esc>", "<c-\\><c-n>")
safe_map("n", "<SPACE>mt", function()
  require("make.terminal").toggle()
end, { desc = "Toggle make terminal" })
safe_map("n", "<SPACE>mr", function()
  require("make.targets").run()
end, { desc = "Run make targets" })
