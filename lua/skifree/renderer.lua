-- Renderer module - handles display
local M = {}

local buf = nil
local win = nil
local saved_guicursor = nil

local GAME_WIDTH = 60
local GAME_HEIGHT = 20

function M.create_window()
	-- Save original cursor
	saved_guicursor = vim.o.guicursor

	-- Create scratch buffer
	buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false

	-- Calculate centered position
	local ui = vim.api.nvim_list_uis()[1]
	local width = ui and ui.width or 80
	local height = ui and ui.height or 24

	local row = math.floor((height - GAME_HEIGHT) / 2) - 1
	local col = math.floor((width - GAME_WIDTH) / 2)

	-- Create floating window
	win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = GAME_WIDTH,
		height = GAME_HEIGHT,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
		title = " SkiFree ",
		title_pos = "center",
	})

	-- Window options
	vim.wo[win].cursorline = false
	vim.wo[win].number = false
	vim.wo[win].relativenumber = false

	-- Hide cursor
	vim.opt.guicursor = "a:hor1-Cursor/lCursor"
end

function M.close_window()
	-- Restore cursor
	if saved_guicursor then
		vim.opt.guicursor = saved_guicursor
	end

	if win and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)
	end
	if buf and vim.api.nvim_buf_is_valid(buf) then
		vim.api.nvim_buf_delete(buf, { force = true })
	end
	buf = nil
	win = nil
end

function M.render(lines)
	if buf and vim.api.nvim_buf_is_valid(buf) then
		vim.bo[buf].modifiable = true
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
		vim.bo[buf].modifiable = false
	end
end

function M.get_buf()
	return buf
end

function M.get_dimensions()
	return GAME_WIDTH, GAME_HEIGHT
end

return M
