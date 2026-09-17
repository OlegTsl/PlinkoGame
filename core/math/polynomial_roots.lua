local M = {}

local function evaluate(c, x)
	local value = c[#c]
	for i = #c - 1, 1, -1 do value = value * x + c[i] end
	return value
end

local function solve(c, lo, hi, epsilon, iterations)
	local degree = #c - 1
	if degree == 0 then return {} end
	if degree == 1 then
		local root = -c[1] / c[2]
		return root >= lo and root <= hi and { root } or {}
	end
	local derivative = {}
	for i = 2, #c do derivative[i - 1] = (i - 1) * c[i] end
	local critical = solve(derivative, lo, hi, epsilon, iterations)
	local boundaries = { lo }
	for _, value in ipairs(critical) do boundaries[#boundaries + 1] = value end
	boundaries[#boundaries + 1] = hi
	local result = {}
	local function add(root)
		if #result == 0 or math.abs(root - result[#result]) > epsilon then
			result[#result + 1] = root
		end
	end
	for i = 1, #boundaries - 1 do
		local a, b = boundaries[i], boundaries[i + 1]
		local fa, fb = evaluate(c, a), evaluate(c, b)
		if math.abs(fa) <= epsilon then add(a) end
		if fa * fb < 0 then
			for _ = 1, iterations do
				local middle = (a + b) * 0.5
				local fm = evaluate(c, middle)
				if fa * fm <= 0 then b = middle else a, fa = middle, fm end
				if b - a <= epsilon then break end
			end
			add((a + b) * 0.5)
		end
	end
	if math.abs(evaluate(c, hi)) <= epsilon then add(hi) end
	return result
end

function M.unit_interval(coefficients, epsilon, iterations)
	local scale = 0
	for _, value in ipairs(coefficients) do scale = math.max(scale, math.abs(value)) end
	if scale == 0 then return {} end
	local normalized = {}
	for i, value in ipairs(coefficients) do normalized[i] = value / scale end
	while #normalized > 1 and normalized[#normalized] == 0 do
		normalized[#normalized] = nil
	end
	return solve(normalized, 0, 1, epsilon, iterations)
end

return M
