local M = {}

function M.calculate(balls, regen_timestamp, maximum, delay, wall_now, output)
	local result = output or {}
	local next_balls = balls
	local next_timestamp = regen_timestamp

	if next_balls >= maximum then
		result.balls, result.regen_timestamp = next_balls, next_timestamp
		result.seconds_to_next, result.changed = nil, false
		return result
	end

	if next_timestamp <= 0 or next_timestamp > wall_now then
		next_timestamp = wall_now
	end

	local elapsed = math.max(0, wall_now - next_timestamp)
	local restored = math.min(maximum - next_balls, math.floor(elapsed / delay))
	if restored > 0 then
		next_balls = math.min(maximum, next_balls + restored)
		if next_balls >= maximum then
			next_timestamp = wall_now
		else
			next_timestamp = next_timestamp + restored * delay
		end
	end

	local seconds_to_next
	if next_balls < maximum then
		seconds_to_next = math.ceil(math.max(0, delay - (wall_now - next_timestamp)))
	end

	result.balls, result.regen_timestamp = next_balls, next_timestamp
	result.seconds_to_next = seconds_to_next
	result.changed = next_balls ~= balls or next_timestamp ~= regen_timestamp
	return result
end

return M
