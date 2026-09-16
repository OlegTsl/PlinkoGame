local random = require("model.random")
local trajectory = require("motion.trajectory")
local collision_world = require("physics.collision_world")
local route_bank = require("motion.route_bank")

local M = {}

local function push(events, event)
	events[#events + 1] = event
end

function M.create(config, physics_data, layout)
	local weight_sum = 0
	for _, item in ipairs(config.baskets.items) do
		if item.weight < 0 then return nil, "Negative basket weight" end
		weight_sum = weight_sum + item.weight
	end
	if math.abs(weight_sum - 1) > config.random.weight_epsilon then
		return nil, "Basket weights must sum to 1"
	end
	local context = {
		config = config,
		physics = physics_data,
		layout = layout,
		world = collision_world.create(layout, physics_data),
		bank = route_bank.create(config, layout),
		active = {},
		next_ball_id = 1,
		outcome_seed = config.random.outcome_seed,
		visual_seed = config.random.visual_seed,
	}
	return context
end

local function activate(context, route, next_visual_seed)
	local target_bucket = context.pending.target
	local ball = {
		id = context.next_ball_id,
		target_bucket = target_bucket,
		route = route,
		elapsed = 0,
		segment_index = 1,
		next_contact_index = 1,
		phase = "falling",
	}
	context.next_ball_id = context.next_ball_id + 1
	context.visual_seed = next_visual_seed
	context.active[#context.active + 1] = ball
	context.pending = nil

	return {
		{
			type = "ball_spawned",
			ball_id = ball.id,
			target_bucket = target_bucket,
			position = route.spawn,
		},
	}
end

-- A request fixes its outcome immediately. A missing physical route leaves
-- that same request pending while bounded background work continues.
function M.spawn(context)
	if context.error then return nil, context.error end
	if context.pending then return nil, "Preparing bucket " .. context.pending.target end
	if #context.active >= context.config.runtime.max_active_balls then
		return nil, "active ball limit reached"
	end
	local value, seed = random.next(context.outcome_seed)
	local target = random.weighted(context.config.baskets.items, value)
	context.outcome_seed = seed
	context.pending = { target = target, started_attempt = context.bank.attempts }
	local route, visual_seed = route_bank.take(context.bank, target, context.visual_seed)
	if route then return activate(context, route, visual_seed) end
	return { { type = "spawn_pending", target_bucket = target } }
end

local function update_falling(context, ball, step, events)
	local previous = ball.elapsed
	ball.elapsed = math.min(previous + step, ball.route.duration)

	while ball.next_contact_index <= #ball.route.contacts do
		local contact = ball.route.contacts[ball.next_contact_index]
		if contact.time > ball.elapsed then
			break
		end
		push(events, {
			type = contact.kind == "pin" and "pin_hit" or "wall_hit",
			ball_id = ball.id,
			pin_id = contact.pin_id,
			contact_time = contact.time,
			collider_id = contact.collider_id,
			age = ball.elapsed - contact.time,
			strength = contact.strength,
		})
		ball.next_contact_index = ball.next_contact_index + 1
	end

	local position
	position, ball.segment_index = trajectory.sample(
		ball.route,
		ball.elapsed,
		ball.segment_index
	)
	push(events, {
		type = "ball_pose",
		ball_id = ball.id,
		position = position,
		scale = 1,
		alpha = 1,
	})

	if ball.elapsed >= ball.route.duration then
		local segment = ball.route.segments[#ball.route.segments]
		ball.phase = "exiting"
		ball.exit_x = ball.route.final_position.x
		ball.exit_y = ball.route.final_position.y
		ball.exit_vx = segment.vx
		ball.exit_vy = segment.vy - segment.gravity * segment.duration
		push(events, {
			type = "ball_landed",
			ball_id = ball.id,
			target_bucket = ball.target_bucket,
		})
	end
end

local function update_exiting(context, ball, step, events)
	local remaining = step
	local contacts = 0
	while remaining > context.physics.time_epsilon
		and contacts < context.physics.max_contacts do
		local state = {
			x = ball.exit_x,
			y = ball.exit_y,
			vx = ball.exit_vx,
			vy = ball.exit_vy,
		}
		local hit = collision_world.first_hit(context.world, state, remaining, true)
		local elapsed = hit and hit.time or remaining
		ball.exit_x = ball.exit_x + ball.exit_vx * elapsed
		ball.exit_y = ball.exit_y + ball.exit_vy * elapsed
			- 0.5 * context.world.gravity * elapsed * elapsed
		ball.exit_vy = ball.exit_vy - context.world.gravity * elapsed
		remaining = remaining - elapsed

		if not hit then
			break
		end

		local normal_velocity = ball.exit_vx * hit.nx + ball.exit_vy * hit.ny
		local tangent_x = ball.exit_vx - normal_velocity * hit.nx
		local tangent_y = ball.exit_vy - normal_velocity * hit.ny
		ball.exit_vx = context.physics.tangent_retention * tangent_x
			- hit.restitution * normal_velocity * hit.nx
		ball.exit_vy = context.physics.tangent_retention * tangent_y
			- hit.restitution * normal_velocity * hit.ny
		contacts = contacts + 1
	end

	local position = {
		x = ball.exit_x,
		y = ball.exit_y,
	}
	push(events, {
		type = "ball_pose",
		ball_id = ball.id,
		position = position,
		scale = 1,
		alpha = 1,
	})
	return position.y + context.world.radius < 0
end

function M.update(context, dt, deadline_reached)
	local events = {}
	if not context.error then
		route_bank.update(context.bank, context.world, context.config, context.physics, deadline_reached)
	end
	if context.pending and not context.error then
		local target = context.pending.target
		local route, seed = route_bank.take(context.bank, target, context.visual_seed)
		if route then
			local spawned = activate(context, route, seed)
			push(events, spawned[1])
		elseif context.bank.attempts - context.pending.started_attempt >= context.config.motion.max_search_candidates then
			context.error = "No physical route to bucket " .. target .. "; adjust launch/field settings"
			push(events, { type = "motion_error", message = context.error })
		end
	end
	local step = math.min(math.max(dt, 0), context.config.runtime.max_visual_step)
	local remaining = {}
	for index = 1, #context.active do
		local ball = context.active[index]
		local removed = false
		if ball.phase == "falling" then
			update_falling(context, ball, step, events)
		else
			removed = update_exiting(context, ball, step, events)
		end

		if removed then
			push(events, { type = "ball_removed", ball_id = ball.id })
		else
			remaining[#remaining + 1] = ball
		end
	end
	context.active = remaining
	return events
end

return M
