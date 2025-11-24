-- SkiFree for Neovim
local M = {}

M.config = {}
M._running = false
M._autocmd_group = nil

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

function M.start()
	-- Prevent multiple instances
	if M._running then
		vim.notify("SkiFree is already running!", vim.log.levels.WARN)
		return
	end

	local game = require("skifree.game")
	local renderer = require("skifree.renderer")
	local input = require("skifree.input")

	M._running = true

	-- Initialize game state
	game.init()

	-- Create game window
	renderer.create_window()

	-- Setup controls
	input.setup(renderer.get_buf())

	-- Setup focus handling - pause when window loses focus
	M._autocmd_group = vim.api.nvim_create_augroup("SkiFreeFocus", { clear = true })
	vim.api.nvim_create_autocmd("WinLeave", {
		group = M._autocmd_group,
		buffer = renderer.get_buf(),
		callback = function()
			if not game.state.paused and not game.state.game_over then
				game.toggle_pause()
			end
		end,
	})

	-- Start game loop
	game.start_loop()
end

function M.stop()
	local game = require("skifree.game")
	local renderer = require("skifree.renderer")

	game.stop_loop()
	renderer.close_window()

	-- Cleanup autocmds
	if M._autocmd_group then
		vim.api.nvim_del_augroup_by_id(M._autocmd_group)
		M._autocmd_group = nil
	end

	M._running = false
end

return M
