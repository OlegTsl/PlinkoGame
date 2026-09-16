local level_layout = require("model.level_layout")

local M = {}
local SCORE_POP_DURATION = 0.35
local SCORE_POP_SCALE = 2.4

local DEFAULT_NODE_IDS = {
	level_root            = "level_root",
	spawn_anchor          = "spawn_anchor",
	pin_area_anchor       = "pin_area_anchor",
	basket_area_anchor    = "basket_area_anchor",
	pin_template          = "pin_template",
	basket_template       = "basket_template",
	basket_fill_template       = "basket_fill_template",
	basket_left_side_template  = "basket_left_side_template",
	basket_right_side_template = "basket_right_side_template",
	basket_label_template = "basket_label_template",
	basket_score_pop_template = "basket_score_pop_template",
}

local function resolve_nodes(ids)
	local nodes = {}
	for key, default_id in pairs(DEFAULT_NODE_IDS) do
		nodes[key] = gui.get_node(ids and ids[key] or default_id)
	end
	return nodes
end

local function set_enabled_for_tree(clones, enabled)
	for _, node in pairs(clones) do
		gui.set_enabled(node, enabled)
	end
end

local function get_clone(clones, source_id)
	return clones[hash(source_id)] or clones[source_id]
end

local function node_rect_in_field(node, field_size)
	local position = gui.get_position(node)
	local size     = gui.get_size(node)
	local center_x = position.x + field_size.x * 0.5
	local center_y = position.y + field_size.y * 0.5
	return {
		left   = center_x - size.x * 0.5,
		right  = center_x + size.x * 0.5,
		bottom = center_y - size.y * 0.5,
		top    = center_y + size.y * 0.5,
	}
end

local function point_in_field(node, field_size)
	local position = gui.get_position(node)
	return {
		x = position.x + field_size.x * 0.5,
		y = position.y + field_size.y * 0.5,
	}
end

local function to_gui_position(layout, x, y)
	return vmath.vector3(x - layout.width * 0.5, y - layout.height * 0.5, 0)
end

local function delete_dynamic_nodes(context)
	for index = #context.dynamic_roots, 1, -1 do
		gui.delete_node(context.dynamic_roots[index])
	end
	context.dynamic_roots = {}
	context.basket_score_pops = {}
	context.score_pop_versions = {}
	context.layout        = nil
end

local function build_parameters(context, specification)
	local field_size = gui.get_size(context.nodes.level_root)
	local pin_size   = gui.get_size(context.nodes.pin_template)
	return {
		basket_count = specification.basket_count,
		basket_items = specification.basket_items,
		limits       = specification.limits,
		field        = { width = field_size.x, height = field_size.y },
		spawn        = point_in_field(context.nodes.spawn_anchor, field_size),
		pin_area     = node_rect_in_field(context.nodes.pin_area_anchor, field_size),
		basket_area  = node_rect_in_field(context.nodes.basket_area_anchor, field_size),
		pin_radius   = math.min(pin_size.x, pin_size.y)
			* specification.pin_art.radius / specification.pin_art.image_size,
	}
end

local function create_pin_nodes(context, layout)
	for index = 1, #layout.pins do
		local pin  = layout.pins[index]
		local node = gui.clone(context.nodes.pin_template)
		gui.set_parent(node, context.nodes.level_root)
		gui.set_position(node, to_gui_position(layout, pin.x, pin.y))
		local art = context.pin_art
		local size = gui.get_size(node)
		local position = gui.get_position(node)
		position.x = position.x + (0.5 - art.center_x / art.image_size) * size.x
		position.y = position.y + (art.center_y / art.image_size - 0.5) * size.y
		gui.set_position(node, position)
		gui.set_enabled(node, true)
		context.dynamic_roots[#context.dynamic_roots + 1] = node
	end
end

local function create_basket_nodes(context, layout)
	for index = 1, #layout.baskets do
		local basket = layout.baskets[index]
		local clones = gui.clone_tree(context.nodes.basket_template)
		local root  = get_clone(clones, DEFAULT_NODE_IDS.basket_template)
		local fill  = get_clone(clones, DEFAULT_NODE_IDS.basket_fill_template)
		local left  = get_clone(clones, DEFAULT_NODE_IDS.basket_left_side_template)
		local right = get_clone(clones, DEFAULT_NODE_IDS.basket_right_side_template)
		local label = get_clone(clones, DEFAULT_NODE_IDS.basket_label_template)
		local score_pop = get_clone(clones, DEFAULT_NODE_IDS.basket_score_pop_template)
		if not root or not fill or not left or not right or not label or not score_pop then
			error("LevelBuilder: basket template tree is incomplete")
		end

		local side_width = gui.get_size(left).x
		gui.set_parent(root, context.nodes.level_root)
		gui.set_position(root, to_gui_position(layout, basket.x, basket.y))
		gui.set_size(fill, vmath.vector3(math.max(0, basket.width - side_width * 2), basket.height, 0))
		gui.set_position(left, vmath.vector3(-basket.width * 0.5 + side_width * 0.5, 0, 0))
		gui.set_position(right, vmath.vector3(basket.width * 0.5 - side_width * 0.5, 0, 0))
		gui.set_size(left, vmath.vector3(side_width, basket.height, 0))
		gui.set_size(right, vmath.vector3(side_width, basket.height, 0))
		gui.set_text(label, tostring(basket.score))
		gui.set_text(score_pop, tostring(basket.score))
		set_enabled_for_tree(clones, true)
		gui.set_enabled(score_pop, false)
		context.basket_score_pops[basket.id] = score_pop
		context.score_pop_versions[basket.id] = 0
		context.dynamic_roots[#context.dynamic_roots + 1] = root
	end
end

function M.create(node_ids)
	local context = {
		nodes         = resolve_nodes(node_ids),
		dynamic_roots = {},
		basket_score_pops = {},
		score_pop_versions = {},
		layout        = nil,
	}

	gui.set_enabled(context.nodes.spawn_anchor, false)
	gui.set_enabled(context.nodes.pin_area_anchor, false)
	gui.set_enabled(context.nodes.basket_area_anchor, false)
	gui.set_enabled(context.nodes.pin_template, false)
	gui.set_enabled(context.nodes.basket_template, false)
	return context
end

function M.play_score_pop(context, basket_id)
	local node = context.basket_score_pops[basket_id]
	if not node then
		return
	end

	local version = (context.score_pop_versions[basket_id] or 0) + 1
	context.score_pop_versions[basket_id] = version
	gui.set_enabled(node, true)
	gui.set_scale(node, vmath.vector3(1, 1, 1))
	local color = gui.get_color(node)
	color.w = 1
	gui.set_color(node, color)

	gui.animate(
		node,
		gui.PROP_SCALE,
		vmath.vector3(SCORE_POP_SCALE, SCORE_POP_SCALE, 1),
		gui.EASING_OUTQUAD,
		SCORE_POP_DURATION
	)
	gui.animate(
		node,
		gui.PROP_COLOR,
		vmath.vector4(color.x, color.y, color.z, 0),
		gui.EASING_INQUAD,
		SCORE_POP_DURATION,
		0,
		function()
			if context.score_pop_versions[basket_id] == version then
				gui.set_enabled(node, false)
			end
		end
	)
end

function M.build(context, specification)
	assert(context, "LevelBuilder: context is required")
	assert(type(specification) == "table", "LevelBuilder: specification is required")
	delete_dynamic_nodes(context)

	local layout, error_message = level_layout.generate(build_parameters(context, specification))
	if not layout then
		return nil, error_message
	end
	context.pin_art = specification.pin_art
	local side = gui.get_size(context.nodes.basket_left_side_template)
	layout.divider_half_width = side.x * 0.5

	create_pin_nodes(context, layout)
	create_basket_nodes(context, layout)
	context.layout = layout
	return layout
end

function M.clear(context)
	if context then
		delete_dynamic_nodes(context)
	end
end

function M.destroy(context)
	M.clear(context)
end

return M
