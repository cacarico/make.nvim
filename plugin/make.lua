-- plugin/make.lua
-- Auto-initialize make.nvim as soon as it's loaded

local ok, make = pcall(require, "make")
if ok then
  make.setup()
end
