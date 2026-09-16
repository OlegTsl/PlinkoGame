local M = {}

local function to_gui_position(layout, point)
	return vmath.vector3(
		point.x - layout.width * 0.5,
		point.y - layout.height * 0.5,
		0
	)
end

function M.create(layout, config)
	local pins = {}
	for index = 1, #layout.pins do
		pins[layout.pins[index].id] = layout.pins[index]
	end
	local context = {
		layout = layout,
		config = config,
		level_root = gui.get_node("level_root"),
		ball_template = gui.get_node("spawn_anchor"),
		wave_template = gui.get_node("wave_template"),
		balls = {},
		waves = {},
		free_balls = {},
		free_waves = {},
		allocated = {},
		wave_count = 0,
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
	local art = context.config.art.ball
	local size = context.config.physics.ball_radius_ratio * context.layout.basket_width
		* art.image_size / art.radius * scale
	local point = to_gui_position(context.layout, position)
	point.x = point.x + (0.5 - art.center_x / art.image_size) * size
	point.y = point.y + (art.center_y / art.image_size - 0.5) * size
	return point
end

local function spawn_ball(context, event)
	local node = acquire(context, context.ball_template, context.free_balls)
	local art = context.config.art.ball
	local size = context.config.physics.ball_radius_ratio * context.layout.basket_width
		* art.image_size / art.radius
	gui.set_size(node, vmath.vector3(size, size, 0))
	gui.set_position(node, ball_position(context, event.position, 1))
	gui.set_scale(node, vmath.vector3(1, 1, 1))
	gui.set_color(node, vmath.vector4(1, 1, 1, 1))
	context.balls[event.ball_id] = node
end

local function apply_pose(context, event)
	local node = context.balls[event.ball_id]
	if not node then
		return
	end
	gui.set_position(node, ball_position(context, event.position, event.scale))
	gui.set_scale(node, vmath.vector3(event.scale, event.scale, 1))
	local color = gui.get_color(node)
	color.w = event.alpha
	gui.set_color(node, color)
end

local function wave_pose(context, item)
	local wave = context.config.ui.wave
	local progress = item.age / wave.duration
	local scale = wave.start_scale + (wave.end_scale - wave.start_scale) * progress
	gui.set_scale(item.node, vmath.vector3(scale, scale, 1))
	gui.set_color(item.node, vmath.vector4(1, 1, 1, wave.start_alpha * (1 - progress)))
end

local function spawn_wave(context, event)
	local pin = context.pins[event.pin_id]
	if not pin or event.age >= context.config.ui.wave.duration then
		return
	end
	if #context.free_waves == 0 then
		if context.wave_count >= context.config.ui.wave.pool_size then return end
		context.wave_count = context.wave_count + 1
	end
	local node = acquire(context, context.wave_template, context.free_waves)
	gui.set_position(node, to_gui_position(context.layout, pin))
	gui.set_size(node, vmath.vector3(pin.radius * 2, pin.radius * 2, 0))
	local item = { node = node, age = event.age }
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
			local node = context.balls[event.ball_id]
			if node then
				gui.set_enabled(node, false)
				context.free_balls[#context.free_balls + 1] = node
				context.balls[event.ball_id] = nil
			end
		end
	end
end

function M.update(context, dt)
	local wave = context.config.ui.wave
	for index = #context.waves, 1, -1 do
		local item = context.waves[index]
		item.age = item.age + math.max(dt, 0)
		if item.age >= wave.duration then
			gui.set_enabled(item.node, false)
			context.free_waves[#context.free_waves + 1] = item.node
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
end

return M
