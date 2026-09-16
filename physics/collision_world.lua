local roots = require("physics.roots")
local M = {}

local function cell_key(x, y) return x .. ":" .. y end

function M.create(layout, physics_data)
	local world = {
		config = physics_data,
		gravity = physics_data.gravity_ratio * layout.basket_width,
		radius = physics_data.ball_radius_ratio * layout.basket_width,
		velocity_epsilon = physics_data.velocity_epsilon_ratio * layout.basket_width,
		cell_size = layout.basket_width,
		cells = {}, max_pin_radius = 0,
		layout = layout,
		left = layout.baskets[1].left,
		right = layout.baskets[#layout.baskets].right,
		top = layout.height,
	}
	for _, pin in ipairs(layout.pins) do
		local key = cell_key(math.floor(pin.x / world.cell_size), math.floor(pin.y / world.cell_size))
		local cell = world.cells[key] or {}
		world.cells[key] = cell
		cell[#cell + 1] = pin
		world.max_pin_radius = math.max(world.max_pin_radius, pin.radius)
	end
	return world
end

local function position(s, g, t)
	return s.x + s.vx * t, s.y + s.vy * t - 0.5 * g * t * t
end

local function circle(world, s, cx, cy, radius, horizon, accept)
	local dx, dy = s.x - cx, s.y - cy
	local vx, vy = s.vx * horizon, s.vy * horizon
	local ay = -0.5 * world.gravity * horizon * horizon
	local candidates = roots.unit_interval({
		dx * dx + dy * dy - radius * radius,
		2 * (dx * vx + dy * vy),
		vx * vx + vy * vy + 2 * dy * ay,
		2 * vy * ay, ay * ay,
	}, world.config.root_epsilon, world.config.root_iterations)
	for _, u in ipairs(candidates) do
		local t = u * horizon
		local x, y = position(s, world.gravity, t)
		local nx, ny = x - cx, y - cy
		local length = math.sqrt(nx * nx + ny * ny)
		nx, ny = nx / length, ny / length
		if s.vx * nx + (s.vy - world.gravity * t) * ny < -world.velocity_epsilon then
			if accept(t, nx, ny, x, y) ~= false then return end
		end
	end
end

local function horizontal(world, s, height, normal, horizon, accept)
	local candidates = roots.unit_interval({
		s.y - height, s.vy * horizon, -0.5 * world.gravity * horizon * horizon,
	}, world.config.root_epsilon, world.config.root_iterations)
	for _, u in ipairs(candidates) do
		local t = u * horizon
		if (s.vy - world.gravity * t) * normal < -world.velocity_epsilon then
			accept(t, s.x + s.vx * t)
		end
	end
end

function M.first_hit(world, s, horizon, ignore_landing)
	local best
	local function offer(t, nx, ny, kind, id, restitution)
		if t >= 0 and t <= horizon and (not best or t < best.time) then
			best = { time = t, nx = nx, ny = ny, kind = kind,
				id = id, restitution = restitution }
		end
	end
	local r, cfg = world.radius, world.config
	local end_x, end_y = position(s, world.gravity, horizon)
	local min_y, max_y = math.min(s.y, end_y), math.max(s.y, end_y)
	local apex = s.vy / world.gravity
	if apex > 0 and apex < horizon then
		max_y = math.max(max_y, s.y + s.vy * apex * 0.5)
	end
	local reach = r + world.max_pin_radius
	local size = world.cell_size
	for ix = math.floor((math.min(s.x, end_x) - reach) / size),
		math.floor((math.max(s.x, end_x) + reach) / size) do
		for iy = math.floor((min_y - reach) / size), math.floor((max_y + reach) / size) do
			local cell = world.cells[cell_key(ix, iy)]
			if cell then
				for _, pin in ipairs(cell) do
					circle(world, s, pin.x, pin.y, r + pin.radius,
						best and best.time or horizon, function(t, nx, ny)
							offer(t, nx, ny, "pin", pin.id, cfg.pin_restitution)
						end)
				end
			end
		end
	end
	local function vertical(x, normal, bottom, top, kind, id, restitution)
		if s.vx * normal >= -world.velocity_epsilon then return end
		local t = (x - s.x) / s.vx
		if t < 0 or t > horizon then return end
		local _, y = position(s, world.gravity, t)
		if y >= bottom and y <= top then offer(t, normal, 0, kind, id, restitution) end
	end
	vertical(world.left + r, 1, -math.huge, math.huge, "wall", "left", cfg.wall_restitution)
	vertical(world.right - r, -1, -math.huge, math.huge, "wall", "right", cfg.wall_restitution)
	horizontal(world, s, world.top - r, -1, horizon, function(t)
		offer(t, 0, -1, "wall", "top", cfg.wall_restitution)
	end)

	local baskets = world.layout.baskets
	local rim = baskets[1].top
	if min_y <= rim + r then
		local half = world.layout.divider_half_width
		for i = 1, #baskets - 1 do
			local x, bottom = baskets[i].right, baskets[i].bottom
			if x + half + r >= math.min(s.x, end_x) and x - half - r <= math.max(s.x, end_x) then
				vertical(x - half - r, -1, bottom, rim, "divider", i, cfg.divider_restitution)
				vertical(x + half + r, 1, bottom, rim, "divider", i, cfg.divider_restitution)
				horizontal(world, s, rim + r, 1, horizon, function(t, px)
					if px >= x - half and px <= x + half then
						offer(t, 0, 1, "divider", i, cfg.divider_restitution)
					end
				end)
				for _, side in ipairs({ -1, 1 }) do
					circle(world, s, x + side * half, rim, r, horizon, function(t, nx, ny)
						if ny >= 0 and nx * side >= 0 then
							offer(t, nx, ny, "divider", i, cfg.divider_restitution)
							return true
						end
						return false
					end)
				end
			end
		end
		if not ignore_landing then
			for _, basket in ipairs(baskets) do
				horizontal(world, s, basket.landing_y, 1, horizon, function(t, x)
					if x >= basket.left + half + r and x <= basket.right - half - r then
						offer(t, 0, 1, "landed", basket.id, 0)
					end
				end)
			end
		end
	end
	return best
end

return M
