local M = {}

local MODULUS = 2147483647
local MULTIPLIER = 16807
local QUOTIENT = 127773
local REMAINDER = 2836

function M.next(seed)
	local high = math.floor(seed / QUOTIENT)
	local next_seed = MULTIPLIER * (seed - high * QUOTIENT) - REMAINDER * high
	if next_seed <= 0 then
		next_seed = next_seed + MODULUS
	end
	return (next_seed - 1) / (MODULUS - 1), next_seed
end

function M.weighted(items, value)
	local cumulative = 0
	local fallback
	for index = 1, #items do
		local weight = items[index].weight
		if weight > 0 then
			fallback = index
			cumulative = cumulative + weight
			if value < cumulative then
				return index
			end
		end
	end
	return fallback
end

function M.index(seed, count)
	local value, next_seed = M.next(seed)
	return math.floor(value * count) + 1, next_seed
end

return M
