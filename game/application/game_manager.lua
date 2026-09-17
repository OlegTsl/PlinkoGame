local regeneration = require("game.systems.regen_system")

local M = {}

local SAVE_RETRY_SECONDS = 1

function M.create(config, state, wall_now, storage)
	local manager = {}
	local last_failed_save
	local save_error
	local statistics
	local inventory = {}

	function manager:save()
		if not state:is_dirty() then
			return true
		end
		local saved, result = storage:save(state:serialize())
		if not saved then
			return nil, result
		end

		state:set_dirty(false)
		last_failed_save, save_error = nil, nil
		return true
	end

	function manager:add_balls(count)
		if type(count) ~= "number" or count < 1 or count >= math.huge or count ~= math.floor(count) then
			return nil, "Ball amount must be a positive integer"
		end
		state:set_balls(state:get_balls() + count)
		return state:get_balls()
	end

	function manager:record_basket_hit(index)
		local basket = config.baskets.items[index]
		if not basket then
			return nil, "Invalid basket index"
		end
		state:record_basket_hit(index)
		state:set_score(state:get_score() + basket.score)
		statistics = nil
		return state:get_score()
	end

	local function build_statistics()
		local hits = state:get_basket_hits()
		local total_hits = 0
		for index = 1, #hits do
			total_hits = total_hits + hits[index]
		end
		local percentages = {}
		for index = 1, #hits do
			percentages[index] = total_hits > 0 and hits[index] * 100 / total_hits or 0
		end
		statistics = {
			hits = hits,
			percentages = percentages,
			total_hits = total_hits,
			score = state:get_score(),
		}
	end

	function manager:get_statistics(output)
		if not statistics then build_statistics() end
		local result = output or { hits = {}, percentages = {} }
		for index = 1, #statistics.hits do
			result.hits[index] = statistics.hits[index]
			result.percentages[index] = statistics.percentages[index]
		end
		result.total_hits, result.score = statistics.total_hits, statistics.score
		return result
	end

	function manager:reset_progress(current_wall_time)
		local erased, result = storage:save({})
		if not erased then
			return nil, result
		end
		state:reset(config.balls.count, current_wall_time)
		state:set_dirty(false)
		statistics = nil
		return true
	end

	function manager:refresh_balls(current_wall_time)
		local result = regeneration.calculate(
			state:get_balls(),
			state:get_regen_timestamp(),
			config.balls.count,
			config.balls.respawn_delay,
			current_wall_time,
			inventory
		)
		if result.changed then
			state:set_balls(result.balls)
			state:set_regen_timestamp(result.regen_timestamp)
		end
		return result
	end

	function manager:consume_balls(count, current_wall_time)
		if type(count) ~= "number" or count < 1 or count >= math.huge or count % 1 ~= 0 then
			return nil, "Ball amount must be a positive integer"
		end
		self:refresh_balls(current_wall_time)
		local current = state:get_balls()
		if current < count then
			return nil, "Not enough balls"
		end
		if current >= config.balls.count then
			state:set_regen_timestamp(current_wall_time)
		end
		state:set_balls(current - count)
		return self:refresh_balls(current_wall_time)
	end

	function manager:update(current_wall_time)
		local result = self:refresh_balls(current_wall_time)
		if not last_failed_save or current_wall_time < last_failed_save
			or current_wall_time - last_failed_save >= SAVE_RETRY_SECONDS then
			local saved, error_message = self:save()
			if not saved then
				last_failed_save, save_error = current_wall_time, error_message
			end
		end
		return result, save_error
	end

	function manager:final()
		return self:save()
	end

	function manager:get_ball_limit()
		return config.balls.count
	end

	function manager:get_respawn_delay()
		return config.balls.respawn_delay
	end

	function manager:get_basket_count()
		return #config.baskets.items
	end

	function manager:get_basket(index)
		local basket = config.baskets.items[index]
		if not basket then
			return nil
		end
		return basket.weight, basket.score
	end

	function manager:get_balls()
		return state:get_balls()
	end

	function manager:get_score()
		return state:get_score()
	end

	function manager:get_regen_timestamp()
		return state:get_regen_timestamp()
	end

	state:reset(config.balls.count, wall_now)
	local snapshot = storage:load()
	if snapshot then state:deserialize(snapshot) end
	manager:refresh_balls(wall_now)
	return manager
end

return M
