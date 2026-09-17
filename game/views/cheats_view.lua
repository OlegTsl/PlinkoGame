local M = {}

local POINTER = hash("pointer")

local UI_SCALE           = 2.5
local LAUNCHER_INITIAL_Y = 220
local WINDOW_INITIAL_X   = 12
local WINDOW_INITIAL_Y   = 72

function M.create(enabled)
	local context = {
		enabled = enabled and imgui ~= nil,
		open = false,
		actions = {},
	}
	if context.enabled then
		imgui.set_ini_filename()
		imgui.set_global_font_scale(UI_SCALE)
		imgui.scale_all_sizes(UI_SCALE)
	end
	return context
end

function M.draw(context)
	local actions = context.actions
	for index = #actions, 1, -1 do
		actions[index] = nil
	end
	if not context.enabled then
		return actions
	end
	local width, height = window.get_size()
	imgui.set_display_size(width, height)
	local launcher_flags = imgui.WINDOWFLAGS_NODECORATION
		+ imgui.WINDOWFLAGS_ALWAYSAUTORESIZE
		+ imgui.WINDOWFLAGS_NOSAVEDSETTINGS
		+ imgui.WINDOWFLAGS_NOFOCUSONAPPEARING
	imgui.set_next_window_pos(0, LAUNCHER_INITIAL_Y, imgui.COND_ONCE)
	local launcher_visible = imgui.begin_window("##CheatsLauncher", nil, launcher_flags)
	if launcher_visible then
		if imgui.button("Cheats") then
			context.open = not context.open
		end
	end
	imgui.end_window()

	if not context.open then
		return actions
	end

	imgui.set_next_window_pos(
		WINDOW_INITIAL_X,
		WINDOW_INITIAL_Y,
		imgui.COND_APPEARING
	)
	local visible, open = imgui.begin_window("Cheats", true)
	context.open = open
	if visible then
		if imgui.button("Add 1 Ball") then
			actions[#actions + 1] = { type = "add_balls", count = 1 }
		end
		if imgui.button("Add 5 Balls") then
			actions[#actions + 1] = { type = "add_balls", count = 5 }
		end
		if imgui.button("Reset Progress") then
			actions[#actions + 1] = { type = "reset_progress" }
		end
	end
	imgui.end_window()
	return actions
end

function M.on_input(context, action_id, action)
	if not context or not context.enabled then
		return false
	end
	local pointer = action
	if action.touch then
		pointer = nil
		for index = 1, #action.touch do
			local touch = action.touch[index]
			if touch.id == context.pointer_id or (not context.pointer_id and touch.pressed) then
				pointer = touch
				context.pointer_id = touch.id
				break
			end
		end
		if not pointer then
			return imgui.want_mouse_input()
		end
	elseif context.pointer_id then
		return imgui.want_mouse_input()
	end
	local _, height = window.get_size()
	local x, y = pointer.screen_x or pointer.x, pointer.screen_y or pointer.y
	if x and y then
		imgui.set_mouse_pos(x, height - y)
	end
	if action_id == POINTER then
		if pointer.pressed then
			imgui.set_mouse_button(imgui.MOUSEBUTTON_LEFT, 1)
		elseif pointer.released then
			imgui.set_mouse_button(imgui.MOUSEBUTTON_LEFT, 0)
			context.pointer_id = nil
		end
	end
	return imgui.want_mouse_input()
end

function M.cancel_input(context)
	if context and context.enabled then
		imgui.set_mouse_button(imgui.MOUSEBUTTON_LEFT, 0)
		context.pointer_id = nil
	end
end

return M
