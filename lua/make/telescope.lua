--- Telescope integration for make.nvim.
--- @module 'make.telescope'
local M     = {}
local utils = require("make.utils")
local log   = vim.log.levels

--- Launch Telescope picker for make targets.
--- @function run
--- @tparam table opts Telescope picker options
--- @tparam table exec_opts Forwarded to `terminal.exec` (e.g. `{ silent=true }`)
function M.run(opts, exec_opts)
  local ok, pickers = pcall(require, "telescope.pickers")
  if not ok then
    vim.notify("Telescope not installed", log.ERROR)
    return
  end
  local finders      = require("telescope.finders")
  local actions      = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local conf         = require("telescope.config").values

  opts = opts or {}
  local targets = utils.parse_makefile()
  if vim.tbl_isempty(targets) then return end

  pickers.new(opts, {
    prompt_title = "Make Targets",
    finder = finders.new_table {
      results   = targets,
      entry_maker = function(entry)
        return {
          value   = entry,
          display = entry.name,
          ordinal = entry.name,
        }
      end,
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local e = action_state.get_selected_entry().value
        require("make.terminal").exec(e.name, exec_opts)
      end)
      return true
    end,
  }):find()
end

--- Telescope picker including target descriptions.
--- @function run_description
--- @tparam table opts Picker options
--- @tparam table exec_opts Forwarded to `terminal.exec` (e.g. `{ close_on_finish=true }`)
function M.run_description(opts, exec_opts)
  local ok, pickers = pcall(require, "telescope.pickers")
  if not ok then
    vim.notify("Telescope not installed", log.ERROR)
    return
  end
  local finders      = require("telescope.finders")
  local actions      = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local conf         = require("telescope.config").values

  opts = opts or {}
  local targets = utils.parse_makefile()
  if vim.tbl_isempty(targets) then return end

  pickers.new(opts, {
    prompt_title = "Make Targets (with Descriptions)",
    finder = finders.new_table {
      results = targets,
      entry_maker = function(entry)
        local disp = entry.name .. (entry.desc ~= "" and " – " .. entry.desc or "")
        return {
          value   = entry,
          display = disp,
          ordinal = entry.name .. " " .. entry.desc,
        }
      end,
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local e = action_state.get_selected_entry().value
        require("make.terminal").exec(e.name, exec_opts)
      end)
      return true
    end,
  }):find()
end

return M
