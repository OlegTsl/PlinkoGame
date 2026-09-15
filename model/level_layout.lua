local M = {}

local EPSILON = 0.000001

local function fail(message)
	return nil, "LevelLayout: " .. message
end

local function is_finite(value)
	return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function is_integer(value)
	return is_finite(value) and value % 1 == 0
end

local function validate_point(name, point)
	if type(point) ~= "table" or not is_finite(point.x) or not is_finite(point.y) then
		return fail(name .. " must contain finite x and y values")
	end
	return true
end

local function validate_rect(name, rect)
	if type(rect) ~= "table" then
		return fail(name .. " must be a table")
	end
	if not is_finite(rect.left) or not is_finite(rect.right)
			or not is_finite(rect.bottom) or not is_finite(rect.top) then
		return fail(name .. " must contain finite left, right, bottom and top values")
	end
	if rect.right <= rect.left or rect.top <= rect.bottom then
		return fail(name .. " must have positive width and height")
	end
	return true
end

local function rect_is_inside(rect, width, height)
	return rect.left >= -EPSILON and rect.bottom >= -EPSILON
		and rect.right <= width + EPSILON and rect.top <= height + EPSILON
end

local function validate_items(items, count)
	if type(items) ~= "table" or #items ~= count then
		return fail("basket_items must contain exactly " .. count .. " entries")
	end
	for index = 1, count do
		local item = items[index]
		if type(item) ~= "table" or not is_finite(item.weight) or not is_finite(item.score) then
			return fail("basket item " .. index .. " must contain numeric weight and score")
		end
	end
	return true
end

local function validate_pin_clearance(pins, radius)
	local diameter = radius * 2
	local minimum_distance_squared = diameter * diameter
	for first = 1, #pins do
		local a = pins[first]
		for second = first + 1, #pins do
			local b = pins[second]
			local dx = b.x - a.x
			local dy = b.y - a.y
			if dx * dx + dy * dy < minimum_distance_squared - EPSILON then
				return fail(string.format(
					"pins %d and %d overlap (pin diameter %.2f)",
					a.id, b.id, diameter
				))
			end
		end
	end
	return true
end

function M.generate(parameters)
	if type(parameters) ~= "table" then
		return fail("parameters must be a table")
	end

	local count = parameters.basket_count
	local limits = parameters.limits
	local field = parameters.field
	local spawn = parameters.spawn
	local pin_area = parameters.pin_area
	local basket_area = parameters.basket_area
	local pin_radius = parameters.pin_radius

	if not is_integer(count) then
		return fail("basket_count must be an integer")
	end
	if type(limits) ~= "table" or not is_integer(limits.min_baskets)
			or not is_integer(limits.max_baskets) or limits.min_baskets > limits.max_baskets then
		return fail("limits must define a valid integer min_baskets/max_baskets range")
	end
	if count < limits.min_baskets or count > limits.max_baskets then
		return fail(string.format(
			"basket_count %d is outside the supported range %d..%d",
			count, limits.min_baskets, limits.max_baskets
		))
	end
	if type(field) ~= "table" or not is_finite(field.width) or not is_finite(field.height)
			or field.width <= 0 or field.height <= 0 then
		return fail("field must have positive finite width and height")
	end

	local ok, error_message = validate_point("spawn", spawn)
	if not ok then return nil, error_message end
	ok, error_message = validate_rect("pin_area", pin_area)
	if not ok then return nil, error_message end
	ok, error_message = validate_rect("basket_area", basket_area)
	if not ok then return nil, error_message end
	ok, error_message = validate_items(parameters.basket_items, count)
	if not ok then return nil, error_message end

	if not is_finite(pin_radius) or pin_radius <= 0 then
		return fail("pin_radius must be positive")
	end
	if not rect_is_inside(pin_area, field.width, field.height) then
		return fail("pin_area must fit inside the field")
	end
	if not rect_is_inside(basket_area, field.width, field.height) then
		return fail("basket_area must fit inside the field")
	end
	if spawn.x < 0 or spawn.x > field.width or spawn.y < 0 or spawn.y > field.height then
		return fail("spawn must be inside the field")
	end
	if spawn.y <= pin_area.top then
		return fail("spawn must be above pin_area")
	end
	if pin_area.bottom <= basket_area.top then
		return fail("pin_area must be above basket_area")
	end

	local basket_width = (basket_area.right - basket_area.left) / count
	if pin_radius * 2 >= basket_width - EPSILON then
		return fail(string.format(
			"pin diameter %.2f must be smaller than basket width %.2f",
			pin_radius * 2, basket_width
		))
	end

	local row_count = count - 1
	local row_spacing = (pin_area.top - pin_area.bottom) / (row_count - 1)
	local pins = {}
	local pin_id = 0

	for row = 1, row_count do
		local pins_in_row = row
		local y = pin_area.top - (row - 1) * row_spacing
		for column = 1, pins_in_row do
			local x = spawn.x + (column - (pins_in_row + 1) / 2) * basket_width
			if x < pin_area.left - EPSILON or x > pin_area.right + EPSILON
					or y < pin_area.bottom - EPSILON or y > pin_area.top + EPSILON then
				return fail(string.format(
					"pin row %d column %d center is outside pin_area",
					row, column
				))
			end
			if x - pin_radius < -EPSILON or x + pin_radius > field.width + EPSILON
					or y - pin_radius < -EPSILON or y + pin_radius > field.height + EPSILON then
				return fail(string.format(
					"pin row %d column %d does not fit inside the field",
					row, column
				))
			end
			pin_id = pin_id + 1
			pins[pin_id] = {
				id = pin_id,
				row = row,
				column = column,
				x = x,
				y = y,
				radius = pin_radius,
			}
		end
	end

	ok, error_message = validate_pin_clearance(pins, pin_radius)
	if not ok then return nil, error_message end

	local baskets = {}
	for index = 1, count do
		local left = basket_area.left + (index - 1) * basket_width
		local right = left + basket_width
		local item = parameters.basket_items[index]
		baskets[index] = {
			id = index,
			left = left,
			right = right,
			bottom = basket_area.bottom,
			top = basket_area.top,
			x = (left + right) * 0.5,
			y = (basket_area.bottom + basket_area.top) * 0.5,
			landing_x = (left + right) * 0.5,
			landing_y = (basket_area.bottom + basket_area.top) * 0.5,
			width = basket_width,
			height = basket_area.top - basket_area.bottom,
			weight = item.weight,
			score = item.score,
		}
	end

	return {
		width = field.width,
		height = field.height,
		basket_count = count,
		basket_width = basket_width,
		row_count = row_count,
		row_spacing = row_spacing,
		spawn = { x = spawn.x, y = spawn.y },
		pins = pins,
		baskets = baskets,
	}
end

return M
