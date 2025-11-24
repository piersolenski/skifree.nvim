-- SkiFree for Neovim

vim.api.nvim_create_user_command("SkiFree", function()
	require("skifree").start()
end, { desc = "Start SkiFree game" })
