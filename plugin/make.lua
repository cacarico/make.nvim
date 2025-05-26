vim.keymap.set("t", "<esc><esc>", "<c-\\><c-n>")

vim.keymap.set("n", "<SPACE>mt", function()
	require("make.terminal").toggle()
end)

vim.keymap.set("n", "<SPACE>me", function()
	require("make.targets").run()
end)
