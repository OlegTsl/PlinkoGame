local M = {}

local UI_SCALE           = 2.5
local LAUNCHER_INITIAL_Y = 220
local WINDOW_INITIAL_X   = 12
local WINDOW_INITIAL_Y   = 72

function M.create(enabled)
	local context = {
		enabled = enabled and imgui ~= nil,
		open = false,
	}
	if context.enabled then
		imgui.set_ini_filename()
		imgui.set_global_font_scale(UI_SCALE)
		imgui.scale_all_sizes(UI_SCALE)
	end
	return context
end

function M.draw(context)
	if not context.enabled then
		return {}
	end

	local actions = {}
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

return M
