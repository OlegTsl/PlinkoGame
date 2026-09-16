local M = {}

local DRAW_DEBUG_TEXT = hash("draw_debug_text")

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
	return { background = background, render_url = msg.url("@render:"), lines = {} }
end

function M.set_visible(context, visible)
	gui.set_enabled(context.background, visible)
end

function M.destroy(context)
	gui.delete_node(context.background)
	context.background = nil
end

-- Reuse message payloads and format text only when displayed values change.
function M.draw(context, statistics)
	local width, height = window.get_size()
	local resized = width ~= context.width or height ~= context.height
	if resized then
		context.width, context.height = width, height
		gui.set_size(context.background, vmath.vector3(width, height, 0))
		gui.set_position(context.background, vmath.vector3(width * 0.5, height * 0.5, 0))
	end
	for line = 0, #statistics.hits do
		local item = context.lines[line]
		if not item then
			item = { message = { position = vmath.vector3(), color = TEXT_COLOR } }
			context.lines[line] = item
		end
		local value = line == 0 and statistics.score or statistics.hits[line]
		if item.value ~= value or (line > 0 and item.total ~= statistics.total_hits) then
			item.value, item.total = value, statistics.total_hits
			if line == 0 then item.message.text = "Total score: " .. tostring(value)
			else item.message.text = string.format("Basket %d: %d hits (%.2f%%)",
				line, value, statistics.percentages[line]) end
		end
		local position = item.message.position
		position.x, position.y = LEFT, height / TEXT_SCALE - TOP - line * LINE_HEIGHT
		msg.post(context.render_url, DRAW_DEBUG_TEXT, item.message)
	end
end

return M
