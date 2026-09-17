local tools = require("utils.utils")

local M = {}
local WEIGHT_EPSILON = 1e-9

local function number(value, name, minimum, maximum, integer)
	assert(type(value) == "number" and value == value and value > -math.huge
		and value < math.huge, name .. " must be finite")
	assert(value >= minimum and value <= maximum, name .. " is out of range")
	assert(not integer or value % 1 == 0, name .. " must be an integer")
	return value
end

local function positive(value, name)
	number(value, name, 0, math.huge)
	assert(value > 0, name .. " must be positive")
end

local function validate(config, physics, motion, runtime, ui)
	tools.is_type(config, tools.T.Table, "config")

	local balls = tools.is_type(config.balls, tools.T.Table, "balls")
	number(balls.count, "balls.count", 1, math.huge, true)
	positive(balls.respawn_delay, "balls.respawn_delay")

	local level = tools.is_type(config.level, tools.T.Table, "level")
	number(level.min_basket_count, "level.min_basket_count", 3, math.huge, true)
	number(level.max_basket_count, "level.max_basket_count", level.min_basket_count, math.huge, true)

	local baskets = tools.is_type(config.baskets, tools.T.Table, "baskets")
	local items = tools.is_type(baskets.items, tools.T.Table, "baskets.items")
	local count = #items

	number(count, "basket count", level.min_basket_count, level.max_basket_count, true)
	for key in pairs(items) do
		number(key, "basket index", 1, count, true)
	end

	local sum = 0
	for index = 1, count do
		local item = tools.is_type(items[index], tools.T.Table, "basket " .. index)
		sum = sum + number(item.weight, "basket weight", 0, 1)
		number(item.score, "basket score", 0, math.huge, true)
	end

	assert(math.abs(sum - 1) <= WEIGHT_EPSILON,
		"Basket weights must sum to 1")

	tools.is_type(motion, tools.T.Table, "motion")
	number(motion.generator_seed, "motion.generator_seed", 1, 2147483646, true)
	for _, key in ipairs({ "routes_per_bucket", "work_units_per_frame", "max_search_candidates" }) do
		number(motion[key], "motion." .. key, 1, math.huge, true)
	end
	positive(motion.preparation_budget_ms, "motion.preparation_budget_ms")

	tools.is_type(runtime, tools.T.Table, "runtime")
	number(runtime.max_active_balls, "runtime.max_active_balls", 1, math.huge, true)
	positive(runtime.max_visual_step, "runtime.max_visual_step")

	tools.is_type(physics, tools.T.Table, "physics")
	for _, key in ipairs({ "gravity_ratio", "ball_radius_ratio", "pin_radius_ratio", "contact_horizon",
		"root_epsilon", "time_epsilon", "velocity_epsilon_ratio", "max_flight_time" }) do
		positive(physics[key], "physics." .. key)
	end
	assert(physics.root_epsilon < 1, "physics.root_epsilon must be below 1")
	assert(physics.time_epsilon < physics.contact_horizon
		and physics.time_epsilon < physics.max_flight_time, "physics time epsilon is too large")
	for _, key in ipairs({ "pin_restitution", "wall_restitution", "divider_restitution", "tangent_retention" }) do
		number(physics[key], "physics." .. key, 0, 1)
	end
	number(physics.spawn_spread_ratio, "physics.spawn_spread_ratio", 0, math.huge)
	number(physics.launch_vx_ratio, "physics.launch_vx_ratio", 0, math.huge)
	number(physics.launch_vy_min_ratio, "physics.launch_vy_min_ratio", -math.huge, math.huge)
	number(physics.launch_vy_max_ratio, "physics.launch_vy_max_ratio", physics.launch_vy_min_ratio, math.huge)
	number(physics.root_iterations, "physics.root_iterations", 1, math.huge, true)
	number(physics.max_contacts, "physics.max_contacts", 1, math.huge, true)
	number(physics.minimum_pin_hits, "physics.minimum_pin_hits", 0, physics.max_contacts, true)
	local ui_config = tools.is_type(ui, tools.T.Table, "ui")
	local wave = tools.is_type(ui_config.wave, tools.T.Table, "ui.wave")
	positive(wave.duration, "wave.duration")
	number(wave.start_scale, "wave.start_scale", 0, math.huge)
	number(wave.end_scale, "wave.end_scale", 0, math.huge)
	number(wave.start_alpha, "wave.start_alpha", 0, 1)
	number(wave.pool_size, "wave.pool_size", 0, math.huge, true)
end

function M.validate(config, physics, motion, runtime, ui)
	local ok, message = pcall(validate, config, physics, motion, runtime, ui)
	if not ok then return nil, "Config: " .. tostring(message) end
	return true
end

return M
