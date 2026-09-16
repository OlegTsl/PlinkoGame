local collision_world = require("physics.collision_world")
local M = {}

function M.create(x, y, vx, vy)
	return {
		x = x, y = y, vx = vx, vy = vy, elapsed = 0,
		flight = { x = x, y = y, vx = vx, vy = vy, start_time = 0 },
		route = { segments = {}, contacts = {}, duration = 0,
			spawn = { x = x, y = y } },
		hits = 0,
	}
end

local function close_flight(candidate, gravity)
	local flight = candidate.flight
	local duration = candidate.elapsed - flight.start_time
	if duration > 0 then
		flight.duration = duration
		flight.finish_time = candidate.elapsed
		flight.gravity = gravity
		candidate.route.segments[#candidate.route.segments + 1] = flight
	end
end

function M.advance(candidate, world)
	local cfg = world.config
	local horizon = math.min(cfg.contact_horizon, cfg.max_flight_time - candidate.elapsed)
	if horizon <= cfg.time_epsilon or #candidate.route.contacts >= cfg.max_contacts then
		return "rejected"
	end
	local hit = collision_world.first_hit(world, candidate, horizon)
	local dt = hit and hit.time or horizon
	candidate.elapsed = candidate.elapsed + dt
	local flight = candidate.flight
	local t = candidate.elapsed - flight.start_time
	candidate.x = flight.x + flight.vx * t
	candidate.y = flight.y + flight.vy * t - 0.5 * world.gravity * t * t
	candidate.vx = flight.vx
	candidate.vy = flight.vy - world.gravity * t
	if not hit then
		if candidate.y < world.layout.baskets[1].bottom then return "rejected" end
		return "running"
	end
	close_flight(candidate, world.gravity)
	if hit.kind == "landed" then
		if candidate.hits < cfg.minimum_pin_hits then return "rejected" end
		local route = candidate.route
		route.duration = candidate.elapsed
		route.target_bucket = hit.id
		route.final_position = { x = candidate.x, y = candidate.y }
		return "landed", route
	end

	if candidate.last_contact_time and candidate.elapsed - candidate.last_contact_time < cfg.time_epsilon then
		return "rejected"
	end
	candidate.last_contact_time = candidate.elapsed
	local nx, ny = hit.nx, hit.ny
	local vn = candidate.vx * nx + candidate.vy * ny
	local tx, ty = candidate.vx - vn * nx, candidate.vy - vn * ny
	candidate.vx = cfg.tangent_retention * tx - hit.restitution * vn * nx
	candidate.vy = cfg.tangent_retention * ty - hit.restitution * vn * ny
	local contact = {
		time = candidate.elapsed, kind = hit.kind, collider_id = hit.id,
		pin_id = hit.kind == "pin" and hit.id or nil,
		x = candidate.x, y = candidate.y, nx = nx, ny = ny, strength = -vn,
	}
	candidate.route.contacts[#candidate.route.contacts + 1] = contact
	if hit.kind == "pin" then candidate.hits = candidate.hits + 1 end
	candidate.flight = {
		x = candidate.x, y = candidate.y, vx = candidate.vx, vy = candidate.vy,
		start_time = candidate.elapsed,
	}
	return "running"
end

return M
