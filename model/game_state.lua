local M = {}

local function non_negative_integer(value, fallback)
	if type(value) ~= "number" or value < 0 or value ~= value then
		return fallback
	end
	return math.floor(value)
end

function M.create(basket_count)
	assert(type(basket_count) == "number" and basket_count >= 1, "basket_count must be positive")
	local balls = 0
	local score = 0
	local regen_timestamp = 0
	local basket_hits = {}
	for index = 1, basket_count do
		basket_hits[index] = 0
	end
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

	function state:get_basket_hit(index)
		return basket_hits[index]
	end

	function state:record_basket_hit(index)
		assert(basket_hits[index] ~= nil, "invalid basket index")
		basket_hits[index] = basket_hits[index] + 1
		dirty = true
	end

	function state:get_basket_hits()
		local copy = {}
		for index = 1, basket_count do
			copy[index] = basket_hits[index]
		end
		return copy
	end

	function state:reset(initial_balls, current_wall_time)
		balls = non_negative_integer(initial_balls, 0)
		score = 0
		regen_timestamp = non_negative_integer(current_wall_time, 0)
		for index = 1, basket_count do
			basket_hits[index] = 0
		end
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
			basket_hits = state:get_basket_hits(),
		}
	end

	function state:deserialize(snapshot)
		assert(type(snapshot) == "table", "snapshot must be a table")
		balls = non_negative_integer(snapshot.balls, 0)
		score = non_negative_integer(snapshot.score, 0)
		regen_timestamp = non_negative_integer(snapshot.regen_timestamp, 0)
		local saved_hits = type(snapshot.basket_hits) == "table" and snapshot.basket_hits or {}
		for index = 1, basket_count do
			basket_hits[index] = non_negative_integer(saved_hits[index], 0)
		end
		dirty = false
	end

	return state
end

return M
