local ball_system = require("model.ball_system")

local M = {}

function M.create(config, physics_data, layout)
	local balls, error_message = ball_system.create(config, physics_data, layout)
	if not balls then
		return nil, error_message
	end
	return { balls = balls, queued_spawns = 0 }
end

function M.spawn(context)
	if context.queued_spawns > 0 then
		return nil, "Multi-spawn is already in progress"
	end
	return ball_system.spawn(context.balls)
end

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

function M.spawn_many(context, count)
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

function M.update(context, dt, deadline_reached)
	local events = ball_system.update(context.balls, dt, deadline_reached)
	if context.queued_spawns > 0 then
		drain_queue(context, events)
	end
	return events
end

return M
