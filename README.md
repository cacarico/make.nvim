<div align="center">

# make.nvim
[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)
[![Neovim](https://img.shields.io/badge/Neovim%200.8+-green.svg?style=for-the-badge&logo=neovim)](https://neovim.io)

</div>

Make.nvim is a plugin to easily run Makefiles.



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


## Getting Started

This plugin automatically sets up the following keymaps in case they are not already taken:


| Keymap             | Functionality                                                  |
|--------------------|----------------------------------------------------------------|
| SUPER + mt         | Toggle make terminal.                                          |
| SUPER + mr         | Runs make target                                               |
