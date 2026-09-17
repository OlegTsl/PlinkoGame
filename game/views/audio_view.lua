local M = {}

local COLLISION_GATE_SECONDS = 0.04
local MAX_COLLISION_SOUNDS   = 5

function M.create()
	local context = {
		collide = msg.url("/audio#collide"),
		collect = msg.url("/audio#collect"),
		collision_cooldown = 0,
		active_collision_sounds = 0,
	}
	context.on_collision_complete = function()
		context.active_collision_sounds = math.max(0, context.active_collision_sounds - 1)
	end
	return context
end

function M.update(context, dt)
	context.collision_cooldown = math.max(0, context.collision_cooldown - math.max(dt, 0))
end

function M.play_collision(context)
	if context.collision_cooldown > 0
		or context.active_collision_sounds >= MAX_COLLISION_SOUNDS then
		return
	end
	context.collision_cooldown = COLLISION_GATE_SECONDS
	context.active_collision_sounds = context.active_collision_sounds + 1
	sound.play(context.collide, nil, context.on_collision_complete)
end

function M.play_collect(context)
	sound.play(context.collect)
end

return M
