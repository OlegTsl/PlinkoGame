local ball_system = require("model.ball_system")

local M = {}

function M.create(config, layout)
	local balls, error_message = ball_system.create(config, layout)
	if not balls then
		return nil, error_message
	end
	return { balls = balls }
end

function M.spawn(context)
	return ball_system.spawn(context.balls)
end

function M.update(context, dt, deadline_reached)
	return ball_system.update(context.balls, dt, deadline_reached)
end

return M
