local M = {}

local function to_gui_position(context, point)
	local position = context.position
	position.x = point.x - context.layout.width * 0.5
	position.y = point.y - context.layout.height * 0.5
	return position
end

function M.create(layout, art_data, physics_data, ui_data)
	local pins = {}
	for index = 1, #layout.pins do
		pins[layout.pins[index].id] = layout.pins[index]
	end
	local context = {
		layout = layout,
		art = art_data,
		physics = physics_data,
		ui = ui_data,
		level_root = gui.get_node("level_root"),
		ball_template = gui.get_node("spawn_anchor"),
		wave_template = gui.get_node("wave_template"),
		balls = {},
		waves = {},
		free_balls = {},
		free_waves = {},
		allocated = {},
		wave_count = 0,
		free_wave_items = {},
		position = vmath.vector3(),
		scale = vmath.vector3(1, 1, 1),
		color = vmath.vector4(1, 1, 1, 1),
		pins = pins,
	}
	gui.set_enabled(context.wave_template, false)
	return context
end

local function acquire(context, template, pool)
	local node = table.remove(pool)
	if not node then
		node = gui.clone(template)
		gui.set_parent(node, context.level_root)
		context.allocated[#context.allocated + 1] = node
	end
	gui.set_enabled(node, true)
	return node
end

local function ball_position(context, position, scale)
	local art = context.art.ball
	local size = context.physics.ball_radius_ratio * context.layout.basket_width
		* art.image_size / art.radius * scale
	local point = to_gui_position(context, position)
	point.x = point.x + (0.5 - art.center_x / art.image_size) * size
	point.y = point.y + (art.center_y / art.image_size - 0.5) * size
	return point
end

local function spawn_ball(context, event)
	local node = acquire(context, context.ball_template, context.free_balls)
	local art = context.art.ball
	local size = context.physics.ball_radius_ratio * context.layout.basket_width
		* art.image_size / art.radius
	gui.set_size(node, vmath.vector3(size, size, 0))
	gui.set_position(node, ball_position(context, event.position, 1))
	gui.set_scale(node, vmath.vector3(1, 1, 1))
	gui.set_color(node, vmath.vector4(1, 1, 1, 1))
	context.balls[event.ball_id] = { node = node, scale = 1, alpha = 1 }
end

local function apply_pose(context, event)
	local ball = context.balls[event.ball_id]
	if not ball then return end
	gui.set_position(ball.node, ball_position(context, event.position, event.scale))
	if ball.scale ~= event.scale then
		ball.scale = event.scale
		context.scale.x, context.scale.y = event.scale, event.scale
		gui.set_scale(ball.node, context.scale)
	end
	if ball.alpha ~= event.alpha then
		ball.alpha = event.alpha
		context.color.w = event.alpha
		gui.set_color(ball.node, context.color)
	end
end

local function wave_pose(context, item)
	local wave = context.ui.wave
	local progress = math.min(math.max(item.age / wave.duration, 0), 1)
	progress = progress * progress * (3 - 2 * progress)
	local scale = wave.start_scale + (wave.end_scale - wave.start_scale) * progress
	context.scale.x, context.scale.y = scale, scale
	context.color.w = wave.start_alpha * (1 - progress)
	gui.set_scale(item.node, context.scale)
	gui.set_color(item.node, context.color)
end

local function spawn_wave(context, event)
	local pin = context.pins[event.pin_id]
	if not pin or event.age >= context.ui.wave.duration then
		return
	end
	if #context.free_waves == 0 then
		if context.wave_count >= context.ui.wave.pool_size then return end
		context.wave_count = context.wave_count + 1
	end
	local node = acquire(context, context.wave_template, context.free_waves)
	gui.set_position(node, to_gui_position(context, pin))
	local diameter = pin.radius * 2
	gui.set_size(node, vmath.vector3(diameter, diameter, 0))
	local item = table.remove(context.free_wave_items) or {}
	item.node, item.age = node, event.age
	wave_pose(context, item)
	context.waves[#context.waves + 1] = item
end

function M.apply_events(context, events)
	for index = 1, #events do
		local event = events[index]
		if event.type == "ball_spawned" then
			spawn_ball(context, event)
		elseif event.type == "ball_pose" then
			apply_pose(context, event)
		elseif event.type == "pin_hit" then
			spawn_wave(context, event)
		elseif event.type == "ball_removed" then
			local ball = context.balls[event.ball_id]
			if ball then
				local node = ball.node
				gui.set_enabled(node, false)
				context.free_balls[#context.free_balls + 1] = node
				context.balls[event.ball_id] = nil
			end
		end
	end
end

function M.update(context, dt)
	local wave = context.ui.wave
	for index = #context.waves, 1, -1 do
		local item = context.waves[index]
		item.age = item.age + math.max(dt, 0)
		if item.age >= wave.duration then
			gui.set_enabled(item.node, false)
			context.free_waves[#context.free_waves + 1] = item.node
			context.free_wave_items[#context.free_wave_items + 1] = item
			context.waves[index] = context.waves[#context.waves]
			context.waves[#context.waves] = nil
		else
			wave_pose(context, item)
		end
	end
end

function M.destroy(context)
	for _, node in ipairs(context.allocated) do
		gui.delete_node(node)
	end
	context.balls = {}
	context.waves = {}
	context.allocated = {}
	context.free_balls = {}
	context.free_waves = {}
	context.free_wave_items = {}
	context.wave_count = 0
end

return M
