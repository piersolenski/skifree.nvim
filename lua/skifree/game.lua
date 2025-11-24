-- Game logic and state
local M = {}

local renderer = require("skifree.renderer")
local entities = require("skifree.entities")

local timer = nil
local FRAME_TIME = 80 -- ~12 FPS
local SPEEDS = { slow = 0.6, medium = 1.0, fast = 1.5 }
local SPEED_ORDER = { "slow", "medium", "fast" }

-- Game constants
local YETI_SPAWN_DISTANCE = 2000
local COLLISION_DX = 2
local COLLISION_DY = 1
local MIN_OBSTACLES = 8
local OBSTACLE_SPAWN_CHANCE_LOW = 0.25
local OBSTACLE_SPAWN_CHANCE_HIGH = 0.5
local SKIER_SPAWN_CHANCE = 0.02
local TREE_SPAWN_RATIO = 0.7

-- Game state
M.state = {
	running = false,
	paused = false,
	game_over = false,
	distance = 0,
	player = {
		x = 30,
		y = 4,
		crashed = false,
		speed = "medium",
	},
	frame_count = 0,
	scroll_accum = 0,
	obstacles = {},
	other_skiers = {},
	yeti = nil,
	yeti_spawned = false,
}

function M.init()
	local width = renderer.get_dimensions()
	M.state = {
		running = true,
		paused = false,
		game_over = false,
		distance = 0,
		player = {
			x = math.floor(width / 2),
			y = 4,
			crashed = false,
			speed = "medium",
		},
		obstacles = {},
		other_skiers = {},
		yeti = nil,
		yeti_spawned = false,
		frame_count = 0,
		scroll_accum = 0,
	}
end

function M.start_loop()
	timer = vim.uv.new_timer()

	local update = vim.schedule_wrap(function()
		if not M.state.running then
			M.stop_loop()
			return
		end

		local ok, err = pcall(function()
			if not M.state.paused and not M.state.game_over then
				M.update()
			end
			M.render()
		end)

		if not ok then
			vim.notify("SkiFree error: " .. tostring(err), vim.log.levels.ERROR)
			M.stop_loop()
		end
	end)

	if timer then
		timer:start(FRAME_TIME, FRAME_TIME, update)
	end
end

function M.stop_loop()
	if timer then
		if not timer:is_closing() then
			timer:stop()
			timer:close()
		end
		timer = nil
	end
end

function M.update()
	local state = M.state
	local player = state.player
	local width, height = renderer.get_dimensions()

	-- Always moving downward
	local speed = SPEEDS[player.speed] or SPEEDS.medium
	state.distance = state.distance + speed
	state.frame_count = (state.frame_count or 0) + 1

	-- Scroll obstacles up
	state.scroll_accum = (state.scroll_accum or 0) + speed
	local scroll_amount = math.floor(state.scroll_accum)
	state.scroll_accum = state.scroll_accum - scroll_amount

	if scroll_amount > 0 then
		for i = #state.obstacles, 1, -1 do
			local obs = state.obstacles[i]
			obs.y = obs.y - scroll_amount
			if obs.y < 1 then
				table.remove(state.obstacles, i)
			end
		end

		-- Also scroll other skiers by same amount
		for i = #state.other_skiers, 1, -1 do
			local skier = state.other_skiers[i]
			skier.y = skier.y - scroll_amount
			if skier.y < 1 then
				table.remove(state.other_skiers, i)
			end
		end

		-- Spawn new obstacles - ensure there's always enough on screen
		local spawn_chance = #state.obstacles < MIN_OBSTACLES and OBSTACLE_SPAWN_CHANCE_HIGH
			or OBSTACLE_SPAWN_CHANCE_LOW
		if math.random() < spawn_chance then
			local obs_type = math.random() < TREE_SPAWN_RATIO and "tree" or "rock"
			table.insert(state.obstacles, {
				x = math.random(2, width - 3),
				y = height,
				type = obs_type,
			})
		end

		-- Spawn other skiers occasionally (less frequent)
		if math.random() < SKIER_SPAWN_CHANCE then
			table.insert(state.other_skiers, {
				x = math.random(2, width - 3),
				y = height,
				vx = math.random(-1, 1), -- lateral movement
			})
		end

		-- Update other skiers lateral movement
		for _, skier in ipairs(state.other_skiers) do
			if state.frame_count % 3 == 0 then
				skier.x = skier.x + skier.vx
				-- Keep in bounds
				if skier.x < 2 or skier.x > width - 3 then
					skier.vx = -skier.vx
				end
			end
		end
	end

	-- Spawn yeti after reaching spawn distance
	if state.distance > YETI_SPAWN_DISTANCE and not state.yeti_spawned then
		state.yeti_spawned = true
		state.yeti = {
			x = math.random(5, width - 5),
			y = height + 5,
		}
	end

	-- Update yeti
	if state.yeti then
		-- Move yeti toward player
		if state.yeti.y > player.y then
			state.yeti.y = state.yeti.y - 0.5
		end
		if state.yeti.x < player.x then
			state.yeti.x = state.yeti.x + 0.3
		elseif state.yeti.x > player.x then
			state.yeti.x = state.yeti.x - 0.3
		end

		-- Yeti catches player
		if math.abs(state.yeti.x - player.x) < COLLISION_DX and math.abs(state.yeti.y - player.y) < COLLISION_DX then
			state.game_over = true
			player.crashed = true
		end
	end

	-- Check collisions with obstacles
	for _, obs in ipairs(state.obstacles) do
		local dx = math.abs(obs.x - player.x)
		local dy = math.abs(obs.y - player.y)
		if dx < COLLISION_DX and dy < COLLISION_DY then
			state.game_over = true
			player.crashed = true
			-- Snap player to collision point for visual feedback
			player.x = obs.x
			player.y = obs.y
			break
		end
	end

	-- Check collisions with other skiers
	for _, skier in ipairs(state.other_skiers) do
		local dx = math.abs(skier.x - player.x)
		local dy = math.abs(skier.y - player.y)
		if dx < COLLISION_DX and dy < COLLISION_DY then
			state.game_over = true
			player.crashed = true
			player.x = skier.x
			player.y = skier.y
			break
		end
	end
end

function M.render()
	local state = M.state
	local width, height = renderer.get_dimensions()

	-- Create empty canvas
	local canvas = {}
	for y = 1, height do
		canvas[y] = {}
		for x = 1, width do
			canvas[y][x] = " "
		end
	end

	-- Draw obstacles
	for _, obs in ipairs(state.obstacles) do
		local y = math.floor(obs.y)
		local x = math.floor(obs.x)
		if y >= 1 and y <= height and x >= 1 and x <= width - 2 then
			canvas[y][x] = entities.sprites[obs.type]
			canvas[y][x + 1] = "" -- emoji takes 2 cells
		end
	end

	-- Draw other skiers
	for _, skier in ipairs(state.other_skiers) do
		local y = math.floor(skier.y)
		local x = math.floor(skier.x)
		if y >= 1 and y <= height and x >= 1 and x <= width - 2 then
			canvas[y][x] = entities.sprites.skier
			canvas[y][x + 1] = ""
		end
	end

	-- Draw yeti
	if state.yeti and state.yeti.x and state.yeti.y then
		local y = math.floor(state.yeti.y)
		local x = math.floor(state.yeti.x)
		if y >= 1 and y <= height and x >= 1 and x <= width - 2 then
			canvas[y][x] = entities.sprites.yeti
			canvas[y][x + 1] = ""
		end
	end

	-- Draw player
	local player = state.player
	if player.y >= 1 and player.y <= height and player.x >= 1 and player.x <= width - 2 then
		local sprite = player.crashed and entities.sprites.crashed or entities.sprites.player
		canvas[player.y][player.x] = sprite
		canvas[player.y][player.x + 1] = ""
	end

	-- Convert canvas to lines
	local lines = {}

	-- Status line
	local status = string.format(" Distance: %dm", math.floor(state.distance))
	if state.paused then
		status = status .. "  PAUSED"
	end
	-- Pad or truncate to width
	if #status < width then
		status = status .. string.rep(" ", width - #status)
	else
		status = status:sub(1, width)
	end
	table.insert(lines, status)
	table.insert(lines, string.rep("─", width))

	-- Game area
	for y = 1, height - 4 do
		local line = ""
		for x = 1, width do
			line = line .. (canvas[y][x] or " ")
		end
		table.insert(lines, line)
	end

	-- Bottom bar
	table.insert(lines, string.rep("─", width))

	-- Controls or game over
	local footer
	if state.game_over then
		local msg = state.yeti and "👹 EATEN!" or "💥 CRASHED!"
		footer = string.format(" %s %dm  [r]estart [q]uit", msg, math.floor(state.distance))
	else
		footer = " h/l:Move  j/k:Speed  [p]ause  [q]uit"
	end
	-- Pad or truncate footer
	if #footer < width then
		footer = footer .. string.rep(" ", width - #footer)
	else
		footer = footer:sub(1, width)
	end
	table.insert(lines, footer)

	renderer.render(lines)
end

function M.turn_left()
	if M.state.game_over then
		return
	end
	local player = M.state.player
	player.x = math.max(2, player.x - 1)
end

function M.turn_right()
	if M.state.game_over then
		return
	end
	local player = M.state.player
	local width = renderer.get_dimensions()
	player.x = math.min(width - 3, player.x + 1)
end

function M.speed_up()
	local player = M.state.player
	for i, s in ipairs(SPEED_ORDER) do
		if s == player.speed and i < #SPEED_ORDER then
			player.speed = SPEED_ORDER[i + 1]
			break
		end
	end
end

function M.speed_down()
	local player = M.state.player
	for i, s in ipairs(SPEED_ORDER) do
		if s == player.speed and i > 1 then
			player.speed = SPEED_ORDER[i - 1]
			break
		end
	end
end

function M.toggle_pause()
	M.state.paused = not M.state.paused
end

function M.restart()
	M.init()
end

function M.quit()
	M.state.running = false
	require("skifree").stop()
end

return M
