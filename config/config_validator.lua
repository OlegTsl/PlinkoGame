local M = {}

local function group(value, name)
	assert(type(value) == "table", name .. " must be a table")
	return value
end

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

local function validate(config, physics, ui)
	group(config, "config")
	local balls = group(config.balls, "balls")
	number(balls.count, "balls.count", 1, math.huge, true)
	positive(balls.respawn_delay, "balls.respawn_delay")
	local level = group(config.level, "level")
	number(level.min_basket_count, "level.min_basket_count", 3, math.huge, true)
	number(level.max_basket_count, "level.max_basket_count", level.min_basket_count, math.huge, true)
	local items = group(group(config.baskets, "baskets").items, "baskets.items")
	local count = #items
	number(count, "basket count", level.min_basket_count, level.max_basket_count, true)
	for key in pairs(items) do
		number(key, "basket index", 1, count, true)
	end
	local sum = 0
	for index = 1, count do
		local item = group(items[index], "basket " .. index)
		sum = sum + number(item.weight, "basket weight", 0, 1)
		number(item.score, "basket score", 0, math.huge, true)
	end
	local random = group(config.random, "random")
	positive(random.weight_epsilon, "random.weight_epsilon")
	assert(random.weight_epsilon < 1 and math.abs(sum - 1) <= random.weight_epsilon,
		"Basket weights must sum to 1")
	-- Park–Miller's state is restricted to 1 .. modulus - 1.
	number(random.outcome_seed, "random.outcome_seed", 1, 2147483646, true)
	number(random.visual_seed, "random.visual_seed", 1, 2147483646, true)
	local motion = group(config.motion, "motion")
	number(motion.generator_seed, "motion.generator_seed", 1, 2147483646, true)
	for _, key in ipairs({ "routes_per_bucket", "work_units_per_frame", "max_search_candidates" }) do
		number(motion[key], "motion." .. key, 1, math.huge, true)
	end
	positive(motion.preparation_budget_ms, "motion.preparation_budget_ms")
	local runtime = group(config.runtime, "runtime")
	number(runtime.max_active_balls, "runtime.max_active_balls", 1, math.huge, true)
	positive(runtime.max_visual_step, "runtime.max_visual_step")
	local art = group(config.art, "art")
	for _, key in ipairs({ "ball", "pin" }) do
		local image = group(art[key], "art." .. key)
		positive(image.image_size, "art image_size")
		positive(image.radius, "art radius")
		number(image.center_x, "art center_x", 0, image.image_size)
		number(image.center_y, "art center_y", 0, image.image_size)
	end
	group(physics, "physics")
	for _, key in ipairs({ "gravity_ratio", "ball_radius_ratio", "contact_horizon",
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
	local wave = group(group(ui, "ui").wave, "ui.wave")
	positive(wave.duration, "wave.duration")
	number(wave.start_scale, "wave.start_scale", 0, math.huge)
	number(wave.end_scale, "wave.end_scale", 0, math.huge)
	number(wave.start_alpha, "wave.start_alpha", 0, 1)
	number(wave.pool_size, "wave.pool_size", 0, math.huge, true)
end

-- Validate once, before persistence or GUI construction can dereference data.
function M.validate(config, physics, ui)
	local ok, message = pcall(validate, config, physics, ui)
	if not ok then return nil, "Config: " .. tostring(message) end
	return true
end

return M
