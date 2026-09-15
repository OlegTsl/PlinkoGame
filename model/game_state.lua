local M = {}

function M.create()
	local balls = 0
	local score = 0
	local regen_timestamp = 0
	local dirty = false
	local state = {}

	function state:get_balls()
		return balls
	end

	function state:set_balls(value)
		if balls == value then
			return
		end
		balls = value
		dirty = true
	end

	function state:get_score()
		return score
	end

	function state:set_score(value)
		if score == value then
			return
		end
		score = value
		dirty = true
	end

	function state:get_regen_timestamp()
		return regen_timestamp
	end

	function state:set_regen_timestamp(value)
		if regen_timestamp == value then
			return
		end
		regen_timestamp = value
		dirty = true
	end

	function state:is_dirty()
		return dirty
	end

	function state:set_dirty(value)
		dirty = value
	end

	function state:serialize()
		return {
			balls = balls,
			score = score,
			regen_timestamp = regen_timestamp,
		}
	end

	function state:deserialize(snapshot)
		balls = snapshot.balls or 0
		score = snapshot.score or 0
		regen_timestamp = snapshot.regen_timestamp or 0
		dirty = false
	end

	return state
end

return M
