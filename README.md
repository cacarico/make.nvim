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
- Select targets using `vim.ui.select` (supports telescope, dressing, etc.)
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

This plugin automatically sets up the following keymaps in case they are not already taken:


| Keymap             | Functionality                                                  |
|--------------------|----------------------------------------------------------------|
| SUPER + mt         | Toggle make terminal.                                          |
| SUPER + mr         | Runs make target                                               |
