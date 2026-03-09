<div align="center">

# make.nvim
[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)
[![Neovim](https://img.shields.io/badge/Neovim%200.8+-green.svg?style=for-the-badge&logo=neovim)](https://neovim.io)

</div>

Make.nvim is a plugin to easily run Makefiles.

**Run Makefile targets directly from Neovim in a persistent terminal split.**

This plugin makes working with `Makefile`s inside Neovim a breeze. It parses your top-level Makefile, lists all available targets, and runs the selected target in an embedded terminal — without disrupting your workflow.

---

## ✨ Features

- Parses the top-level `Makefile` and lists unique targets
- Select targets using `vim.ui.select` (supports telescope 🔭)
- Opens or reuses a terminal at the bottom split of your window
- Sends `make <target>` and follows the output automatically

---

## 🛠️ Requirements

- Neovim 0.8+ (0.10+ recommended for vim.system support)
- A top-level Makefile in your working directory
- make installed in your system

---

## Installation

- Neovim >= 0.8.0+ required
- Install using your favorite plugin manager

Install with Lazy

```lua
{
    "cacarico/make.nvim",
}
```

With packer:
```lua
use {
    "cacarico/make.nvim",
}
```

---

## Getting Started

The plugin auto-initializes on load — no explicit `setup()` call required. Call `setup()` only if you want to override defaults:

```lua
require("make").setup({
  debug             = false,  -- show debug notifications
  term_height       = 5,      -- height of the terminal split
  use_default_keymaps = true, -- set <leader>tm and <leader>mt
  silent            = false,  -- run without a terminal; output goes to quickfix
  close_on_finish   = false,  -- auto-close terminal split when make exits
})
```

### Default keymaps

Set automatically when `use_default_keymaps = true` and the key is not already mapped:

| Keymap        | Functionality                        |
|---------------|--------------------------------------|
| `<leader>tm`  | Toggle make terminal                 |
| `<leader>mt`  | Select and run target (with desc)    |

### Commands

| Command                        | Description                                      |
|--------------------------------|--------------------------------------------------|
| `MakeToggle`                   | Toggle the persistent terminal split             |
| `MakeRun`                      | Pick target (names only) and run                 |
| `MakeRunDescription`           | Pick target with descriptions and run            |
| `MakeRunTelescope`             | Telescope picker (names only)                    |
| `MakeRunTelescopeDescription`  | Telescope picker with descriptions               |
| `MakeRunSilent`                | Run silently — output goes to quickfix           |
| `MakeRunSilentDescription`     | Same, with description picker                    |
| `MakeRunClose`                 | Run in terminal, auto-close when done            |
| `MakeRunCloseDescription`      | Same, with description picker                    |
