local regeneration = require("model.regeneration")

local M = {}

local SAVE_APP_ID    = "plinko_game"
local SAVE_FILE_NAME = "player"

function M.create(config, state, wall_now)
	local has_save_path, save_path = pcall(sys.get_save_file, SAVE_APP_ID, SAVE_FILE_NAME)
	local manager = {}

	function manager:load()
		if not has_save_path then
			return nil, save_path
		end
		local loaded, snapshot = pcall(sys.load, save_path)
		if not loaded then
			return nil, snapshot
		end
		if type(snapshot) ~= "table" or next(snapshot) == nil then
			return nil, "save does not exist"
		end
		state:deserialize(snapshot)
		return true
	end

	function manager:save()
		if not state:is_dirty() then
			return true
		end
		if not has_save_path then
			return nil, save_path
		end

		local saved, result = pcall(sys.save, save_path, state:serialize())
		if not saved then
			return nil, result
		end

		state:set_dirty(false)
		return true
	end

	function manager:refresh_balls(current_wall_time)
		local result = regeneration.calculate(
			state:get_balls(),
			state:get_regen_timestamp(),
			config.balls.count,
			config.balls.respawn_delay,
			current_wall_time
		)
		if result.changed then
			state:set_balls(result.balls)
			state:set_regen_timestamp(result.regen_timestamp)
		end
		return result
	end

	function manager:consume_balls(count, current_wall_time)
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
		self:save()
		return result
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

	function manager:set_balls(value)
		state:set_balls(value)
	end

	function manager:get_score()
		return state:get_score()
	end

	function manager:set_score(value)
		state:set_score(value)
	end

	function manager:get_regen_timestamp()
		return state:get_regen_timestamp()
	end

	function manager:set_regen_timestamp(value)
		state:set_regen_timestamp(value)
	end

	if not manager:load() then
		state:set_balls(config.balls.count)
		state:set_regen_timestamp(wall_now)
	end
	manager:refresh_balls(wall_now)
	return manager
end

return M
