local M = {}

local POINTER = hash("pointer")

local function pointer(action)
	if action.touch and #action.touch > 0 then
		return action.touch[1]
	end
	return action
end

function M.create()
	return {
		button = gui.get_node("spawn_button"),
		log = gui.get_node("status_label"),
		pressed = false,
	}
end

function M.on_input(context, action_id, action)
	if action_id ~= POINTER then
		return nil
	end

	local value = pointer(action)
	local inside = gui.pick_node(context.button, value.x, value.y)
	if value.pressed then
		context.pressed = inside
		if inside then
			gui.play_flipbook(context.button, hash("btn_green_push"))
		end
	elseif value.released then
		local activate = context.pressed and inside
		context.pressed = false
		gui.play_flipbook(context.button, hash("btn_green_normal"))
		if activate then
			return "spawn"
		end
	end
	return nil
end

function M.show_bucket(context, bucket_id, pending)
	gui.set_text(context.log, "Selected bucket: " .. bucket_id .. (pending and " — preparing..." or ""))
	gui.set_color(context.log, vmath.vector4(0.72, 0.82, 0.9, 1))
end

function M.show_error(context, message)
	gui.set_text(context.log, message)
	gui.set_color(context.log, vmath.vector4(1, 0.35, 0.35, 1))
end

function M.cancel_press(context)
	context.pressed = false
	gui.play_flipbook(context.button, hash("btn_green_normal"))
end

return M
