--- Telescope integration for make.nvim.
--- @module 'make.telescope'
local M     = {}
local utils = require("make.utils")
local term  = require("make.terminal")
local log   = vim.log.levels

--- Dispatch to the correct terminal function based on opts.
---@param target string
---@param opts? table
local function exec(target, opts)
  local cfg = require("make.config").values
  opts = opts or {}

  -- Per-call opts win; fall back to config defaults when unset.
  local silent = opts.silent
  if silent == nil then silent = cfg.silent end
  local close = opts.close_on_finish
  if close == nil then close = cfg.close_on_finish end

  if silent then
    term.exec_silent(target, opts)
  elseif close then
    term.exec_autoclose(target, opts)
  else
    term.exec(target, opts)
  end
end

--- Internal: open a Telescope picker for make targets.
---@param opts? table Telescope picker options
---@param exec_opts? table Forwarded to terminal exec functions
---@param show_desc boolean Whether to show target descriptions
local function open_picker(opts, exec_opts, show_desc)
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
    prompt_title = show_desc and "Make Targets (with Descriptions)" or "Make Targets",
    finder = finders.new_table {
      results     = targets,
      entry_maker = function(entry)
        local display = entry.name
        local ordinal = entry.name
        if show_desc then
          display = entry.name .. (entry.desc ~= "" and " – " .. entry.desc or "")
          ordinal = entry.name .. " " .. entry.desc
        end
        return {
          value   = entry,
          display = display,
          ordinal = ordinal,
        }
      end,
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local e = action_state.get_selected_entry().value
        if require("make.config").values.debug then
          vim.notify("Selected target: " .. e.name, log.DEBUG)
        end
        exec(e.name, exec_opts)
      end)
      return true
    end,
  }):find()
end

--- Launch Telescope picker for make targets (names only).
---@param opts? table Telescope picker options
---@param exec_opts? table Forwarded to terminal exec functions
function M.run(opts, exec_opts)
  open_picker(opts, exec_opts, false)
end

--- Launch Telescope picker for make targets with descriptions.
---@param opts? table Telescope picker options
---@param exec_opts? table Forwarded to terminal exec functions
function M.run_description(opts, exec_opts)
  open_picker(opts, exec_opts, true)
end

return M
