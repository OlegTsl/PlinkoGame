local ball_system = require("model.ball_system")

local M = {}
local MULTI_SPAWN_COUNT = 5

local function append_events(target, source)
	for index = 1, #source do
		target[#target + 1] = source[index]
	end
end

local function drain_queue(context, events)
	while context.queued_spawns > 0 do
		local spawned, error_message = ball_system.spawn(context.balls)
		if not spawned then
			return error_message
		end
		context.queued_spawns = context.queued_spawns - 1
		append_events(events, spawned)
		if spawned[#spawned].type == "spawn_pending" then
			break
		end
	end
end

local function spawn_many(context, count)
	if context.queued_spawns > 0 then
		return nil, "Multi-spawn is already in progress"
	end
	context.queued_spawns = count
	local events = {}
	local error_message = drain_queue(context, events)
	if #events == 0 and error_message then
		context.queued_spawns = 0
		return nil, error_message
	end
	return events
end

local function update(context, dt, deadline_reached)
	local events = ball_system.update(context.balls, dt, deadline_reached)
	if context.queued_spawns > 0 then
		drain_queue(context, events)
	end
	return events
end

-- The GUI receives operations and events; motion caches and queue state stay private.
function M.create(config, physics_data, layout, manager)
	local balls, error_message = ball_system.create(config, physics_data, layout)
	if not balls then return nil, error_message end
	local context = { balls = balls, queued_spawns = 0, reserved = 0 }
	local controller = {}

	local function settle(events)
		for index = 1, #events do
			local event = events[index]
			if event.type == "ball_spawned" then
				context.reserved = context.reserved - 1
			elseif event.type == "ball_landed" then
				event.score = manager:record_basket_hit(event.target_bucket)
			elseif event.type == "motion_error" then
				-- A failed pending request and its queued successors never appeared.
				if context.reserved > 0 then manager:add_balls(context.reserved) end
				context.reserved, context.queued_spawns = 0, 0
			end
		end
		return events
	end

	function controller:request(action, wall_now)
		local count
		if action == "spawn" then count = 1
		elseif action == "spawn_many" then count = MULTI_SPAWN_COUNT
		else return nil, "Unknown gameplay action" end
		if context.queued_spawns > 0 then return nil, "Multi-spawn is already in progress" end
		if manager:refresh_balls(wall_now).balls < count then return nil, "Not enough balls" end
		local events, message
		if count == 1 then events, message = ball_system.spawn(context.balls)
		else events, message = spawn_many(context, count) end
		if not events then return nil, message end
		manager:consume_balls(count, wall_now)
		context.reserved = context.reserved + count
		return settle(events)
	end

	function controller:update(dt, deadline_reached)
		return settle(update(context, dt, deadline_reached))
	end

	return controller
end

return M
