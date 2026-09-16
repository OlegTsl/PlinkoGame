local M = {}

-- Several pin contacts may be emitted in one frame. Gate the shared effect so
-- a contact burst cannot exhaust Defold's finite pool of sound voices.
local COLLISION_GATE_SECONDS = 0.04

function M.create()
	return {
		collide = msg.url("/audio#collide"),
		collect = msg.url("/audio#collect"),
		collision_cooldown = 0,
	}
end

function M.update(context, dt)
	context.collision_cooldown = math.max(0, context.collision_cooldown - math.max(dt, 0))
end

function M.play_collision(context)
	if context.collision_cooldown > 0 then
		return
	end
	context.collision_cooldown = COLLISION_GATE_SECONDS
	sound.play(context.collide)
end

function M.play_collect(context)
	sound.play(context.collect)
end

return M
