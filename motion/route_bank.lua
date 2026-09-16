local random = require("model.random")
local simulator = require("physics.simulator")
local M = {}

function M.create(config, layout)
	local bank = {
		seed = config.motion.generator_seed, candidate = nil, attempts = 0,
		buckets = {}, count = 0,
		capacity = #layout.baskets * config.motion.routes_per_bucket,
	}
	for i = 1, #layout.baskets do bank.buckets[i] = {} end
	return bank
end

local function launch(bank, world, config)
	local ux, uvx, uvy
	ux, bank.seed = random.next(bank.seed)
	uvx, bank.seed = random.next(bank.seed)
	uvy, bank.seed = random.next(bank.seed)
	local cfg = config.physics
	local layout, step = world.layout, world.cell_size
	local x = layout.spawn.x + (2 * ux - 1) * cfg.spawn_spread_ratio * step
	local vx = (2 * uvx - 1) * cfg.launch_vx_ratio * step
	local vy = (cfg.launch_vy_min_ratio + uvy * (cfg.launch_vy_max_ratio - cfg.launch_vy_min_ratio)) * step
	bank.attempts = bank.attempts + 1
	return simulator.create(x, layout.spawn.y, vx, vy)
end

function M.update(bank, world, config, deadline_reached)
	if bank.count >= bank.capacity then return end
	for _ = 1, config.motion.work_units_per_frame do
		if deadline_reached and deadline_reached() then return end
		if not bank.candidate then bank.candidate = launch(bank, world, config) end
		local status, route = simulator.advance(bank.candidate, world)
		if status ~= "running" then
			bank.candidate = nil
			if route then
				local bucket = bank.buckets[route.target_bucket]
				if #bucket < config.motion.routes_per_bucket then
					bucket[#bucket + 1] = route
					bank.count = bank.count + 1
				end
			end
		end
		if bank.count >= bank.capacity then return end
	end
end

function M.take(bank, target, seed)
	local bucket = bank.buckets[target]
	if #bucket == 0 then return nil, seed end
	local index, next_seed = random.index(seed, #bucket)
	local route = bucket[index]
	bucket[index] = bucket[#bucket]
	bucket[#bucket] = nil
	bank.count = bank.count - 1
	return route, next_seed
end

return M
