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
	local radius = physics_data.ball_radius_ratio * layout.basket_width
	if layout.basket_width <= 2 * (radius + layout.divider_half_width) then
		return nil, "Ball diameter and basket dividers leave no landing corridor"
	end
	local spread = physics_data.spawn_spread_ratio * layout.basket_width
	if layout.spawn.x - spread - radius < layout.baskets[1].left
		or layout.spawn.x + spread + radius > layout.baskets[#layout.baskets].right
		or layout.spawn.y + radius > layout.height then
		return nil, "Ball launch must fit inside the field walls"
	end
	local context = {
		config = config,
		physics = physics_data,
		layout = layout,
		world = collision_world.create(layout, physics_data),
		bank = route_bank.create(config, layout),
		active = {},
		events = {},
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
	ball.pose = { type = "ball_pose", ball_id = ball.id, position = {}, scale = 1, alpha = 1 }
	ball.exit_state = {}
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

local function update_falling(ball, step, events)
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

	ball.pose.position, ball.segment_index = trajectory.sample(
		ball.route,
		ball.elapsed,
		ball.segment_index,
		ball.pose.position
	)
	push(events, ball.pose)

	if ball.elapsed >= ball.route.duration then
		local segment = ball.route.segments[#ball.route.segments]
		ball.phase = "exiting"
		ball.exit_elapsed = 0
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
		local state = ball.exit_state
		state.x, state.y = ball.exit_x, ball.exit_y
		state.vx, state.vy = ball.exit_vx, ball.exit_vy
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

	local position = ball.pose.position
	position.x, position.y = ball.exit_x, ball.exit_y
	push(events, ball.pose)
	ball.exit_elapsed = ball.exit_elapsed + step
	-- Numerical chatter must never retain an already-scored ball indefinitely.
	return position.y + context.world.radius < 0
		or ball.exit_elapsed >= context.physics.max_flight_time
end

-- Events and pose records are borrowed until the next update; consume synchronously.
function M.update(context, dt, deadline_reached)
	local events = context.events
	for index = #events, 1, -1 do events[index] = nil end
	if not context.error then
		route_bank.update(context.bank, context.world, context.config, context.physics, deadline_reached)
	end
	if context.pending and not context.error then
		local target = context.pending.target
		local completed_attempts = context.bank.attempts - (context.bank.candidate and 1 or 0)
		local route, seed = route_bank.take(context.bank, target, context.visual_seed)
		if route then
			local spawned = activate(context, route, seed)
			push(events, spawned[1])
		elseif completed_attempts - context.pending.started_attempt >= context.config.motion.max_search_candidates then
			context.error = "No physical route to bucket " .. target .. "; adjust launch/field settings"
			push(events, { type = "motion_error", message = context.error })
		end
	end
	local step = math.min(math.max(dt, 0), context.config.runtime.max_visual_step)
	local active_count, kept = #context.active, 0
	for index = 1, active_count do
		local ball = context.active[index]
		local removed = false
		if ball.phase == "falling" then
			update_falling(ball, step, events)
		else
			removed = update_exiting(context, ball, step, events)
		end

		if removed then
			push(events, { type = "ball_removed", ball_id = ball.id })
		else
			kept = kept + 1
			context.active[kept] = ball
		end
	end
	for index = kept + 1, active_count do context.active[index] = nil end
	return events
end

return M
