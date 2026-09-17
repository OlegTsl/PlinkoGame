local M = {}

local POINTER = hash("pointer")
local SCORE_ROLL_DURATION = 0.4
local BUTTON_NORMAL = hash("btn_green_normal")
local BUTTON_PUSH = hash("btn_green_push")

local function format_time(seconds)
	local value = math.max(0, math.ceil(seconds or 0))
	local hours = math.floor(value / 3600)
	local minutes = math.floor(value % 3600 / 60)
	local remaining_seconds = value % 60
	return string.format("%02d:%02d:%02d", hours, minutes, remaining_seconds)
end

function M.create(initial_score, balls, maximum, seconds_to_next)
	local context = {
		buttons = {
			{ node = gui.get_node("spawn_button"), action = "spawn" },
			{ node = gui.get_node("spawn_many_button"), action = "spawn_many" },
		},
		log = gui.get_node("status_label"),
		score_label = gui.get_node("score_label"),
		pressed_button = nil,
		pressed_pointer = nil,
		shown_balls = balls,
		shown_seconds = balls < maximum and seconds_to_next or false,
		displayed_score = initial_score,
		score_from = initial_score,
		score_target = initial_score,
		score_elapsed = SCORE_ROLL_DURATION,
		balls_label = gui.get_node("balls_count_label"),
		timer_label = gui.get_node("regen_timer_label"),
	}
	gui.set_text(context.score_label, "Score: " .. tostring(initial_score))
	gui.set_text(context.balls_label, tostring(balls))
	gui.set_text(context.timer_label,
		balls < maximum and "+1 in " .. format_time(seconds_to_next) or "Ready")
	return context
end

local function set_score_text(context, score)
	gui.set_text(context.score_label, "Score: " .. tostring(score))
end

function M.set_score(context, score)
	context.score_from = context.displayed_score
	context.score_target = score
	context.score_elapsed = 0
end

function M.set_inventory(context, balls, maximum, seconds_to_next)
	if context.shown_balls ~= balls then
		context.shown_balls = balls
		gui.set_text(context.balls_label, tostring(balls))
	end
	local seconds = balls < maximum and seconds_to_next or false
	if context.shown_seconds ~= seconds then
		context.shown_seconds = seconds
		gui.set_text(context.timer_label, seconds and "+1 in " .. format_time(seconds) or "Ready")
	end
end

function M.update(context, dt)
	if context.score_elapsed >= SCORE_ROLL_DURATION then
		return
	end
	context.score_elapsed = math.min(context.score_elapsed + math.max(dt, 0), SCORE_ROLL_DURATION)
	local progress = context.score_elapsed / SCORE_ROLL_DURATION
	progress = progress * progress * (3 - 2 * progress)
	local value = context.score_from + (context.score_target - context.score_from) * progress
	local rounded = math.floor(value + 0.5)
	if rounded ~= context.displayed_score then
		context.displayed_score = rounded
		set_score_text(context, rounded)
	end
end

local function handle_pointer(context, value, id)
	if not value.x or not value.y then return nil end
	if value.pressed and not context.pressed_button then
		for index = 1, #context.buttons do
			local button = context.buttons[index]
			if gui.pick_node(button.node, value.x, value.y) then
				context.pressed_button, context.pressed_pointer = button, id
				gui.play_flipbook(button.node, BUTTON_PUSH)
				break
			end
		end
	elseif value.released and context.pressed_pointer == id then
		local button = context.pressed_button
		context.pressed_button, context.pressed_pointer = nil, nil
		if button then
			gui.play_flipbook(button.node, BUTTON_NORMAL)
			if gui.pick_node(button.node, value.x, value.y) then return button.action end
		end
	end
	return nil
end

function M.on_input(context, action_id, action)
	if action_id ~= POINTER then return nil end
	if action.touch then
		for index = 1, #action.touch do
			local value = action.touch[index]
			local result = handle_pointer(context, value, value.id)
			if result then return result end
		end
		return nil
	end
	return handle_pointer(context, action, "mouse")
end

function M.show_bucket(context, bucket_id, pending)
	gui.set_text(context.log, "Selected bucket: " .. bucket_id .. (pending and " — preparing..." or ""))
	gui.set_color(context.log, vmath.vector4(1, 1, 1, 1))
end

function M.show_error(context, message)
	gui.set_text(context.log, message)
	gui.set_color(context.log, vmath.vector4(1, 0.25, 0.25, 1))
end

function M.cancel_press(context)
	if context.pressed_button then
		gui.play_flipbook(context.pressed_button.node, BUTTON_NORMAL)
		context.pressed_button = nil
		context.pressed_pointer = nil
	end
end

return M
