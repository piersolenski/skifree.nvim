-- Input handling
local M = {}

function M.setup(buf)
	local game = require("skifree.game")

	local keymaps = {
		-- Arrow keys - turn left/right
		{ "<Left>", game.turn_left },
		{ "<Right>", game.turn_right },

		-- Vim keys - turn left/right
		{ "h", game.turn_left },
		{ "l", game.turn_right },

		-- Speed control
		{ "j", game.speed_down },
		{ "k", game.speed_up },
		{ "<Down>", game.speed_down },
		{ "<Up>", game.speed_up },

		-- Actions
		{ "p", game.toggle_pause },
		{ "q", game.quit },
		{
			"r",
			function()
				if game.state.game_over then
					game.restart()
				end
			end,
		},
	}

	for _, map in ipairs(keymaps) do
		vim.api.nvim_buf_set_keymap(buf, "n", map[1], "", {
			noremap = true,
			silent = true,
			callback = map[2],
		})
	end
end

return M
