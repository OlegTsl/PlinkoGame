local M = {}

local function non_negative_integer(value, fallback)
	if type(value) ~= "number" or value < 0 or value ~= value or value == math.huge then
		return fallback
	end
	return math.floor(value)
end

local function require_integer(value)
	assert(type(value) == "number" and non_negative_integer(value) == value,
		"state value must be a finite non-negative integer")
end

function M.create(basket_count)
	require_integer(basket_count)
	assert(basket_count >= 1, "basket_count must be positive")
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
		require_integer(value)
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
		require_integer(value)
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
		assert(type(value) == "number" and value >= 0 and value < math.huge,
			"timestamp must be finite and non-negative")
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
		-- Keep the caller's defaults for damaged or missing fields. A fractional
		-- timestamp is valid when the regeneration interval is fractional.
		balls = non_negative_integer(snapshot.balls, balls)
		score = non_negative_integer(snapshot.score, score)
		local timestamp = snapshot.regen_timestamp
		if type(timestamp) == "number" and timestamp >= 0 and timestamp < math.huge then
			regen_timestamp = timestamp
		end
		local repaired = balls ~= snapshot.balls or score ~= snapshot.score
			or regen_timestamp ~= snapshot.regen_timestamp
		local saved_hits = type(snapshot.basket_hits) == "table" and snapshot.basket_hits or {}
		for index = 1, basket_count do
			basket_hits[index] = non_negative_integer(saved_hits[index], 0)
			repaired = repaired or basket_hits[index] ~= saved_hits[index]
		end
		dirty = repaired
	end

	return state
end

return M
