local M = {}

local TEXT_SCALE = 2.5
local LEFT = 10
local TOP = 20
local LINE_HEIGHT = 16
local BACKGROUND_COLOR = vmath.vector4(0.02, 0.03, 0.05, 0.78)
local TEXT_COLOR = vmath.vector4(1, 1, 1, 1)

function M.create()
	local background = gui.new_box_node(vmath.vector3(), vmath.vector3(1, 1, 0))
	gui.set_color(background, BACKGROUND_COLOR)
	gui.set_enabled(background, false)
	return { background = background }
end

function M.set_visible(context, visible)
	gui.set_enabled(context.background, visible)
end

function M.destroy(context)
	gui.delete_node(context.background)
	context.background = nil
end

local function draw_line(text, line, screen_height)
	msg.post("@render:", "draw_debug_text", {
		text = text,
		position = vmath.vector3(LEFT, screen_height - TOP - line * LINE_HEIGHT, 0),
		color = TEXT_COLOR,
	})
end

-- Sends a read-only statistics snapshot to Defold's debug text renderer.
function M.draw(context, statistics)
	local screen_width, screen_height = window.get_size()
	gui.set_size(context.background, vmath.vector3(
		screen_width,
		screen_height,
		0
	))
	gui.set_position(context.background, vmath.vector3(
		screen_width * 0.5,
		screen_height * 0.5,
		0
	))

	local logical_screen_height = screen_height / TEXT_SCALE
	draw_line("Total score: " .. tostring(statistics.score), 0, logical_screen_height)
	for index = 1, #statistics.hits do
		draw_line(string.format(
			"Basket %d: %d hits (%.2f%%)",
			index,
			statistics.hits[index],
			statistics.percentages[index]
		), index, logical_screen_height)
	end
end

return M
