local M = {}

function M.sample(route, elapsed, segment_index, output)
	local index = segment_index or 1
	while index < #route.segments and elapsed >= route.segments[index].finish_time do
		index = index + 1
	end

	local arc = route.segments[index]
	local t = math.max(0, math.min(elapsed - arc.start_time, arc.duration))
	local position = output or {}
	position.x = arc.x + arc.vx * t
	position.y = arc.y + arc.vy * t - 0.5 * arc.gravity * t * t
	return position, index
end

return M
