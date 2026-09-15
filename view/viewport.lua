local M = {}

function M.create(content_root, background, design_width, design_height)
	assert(design_width > 0 and design_height > 0, "Viewport: invalid design size")
	return {
		content_root  = content_root,
		background    = background,
		design_width  = design_width,
		design_height = design_height,
		window_width  = 0,
		window_height = 0,
	}
end

function M.update(context)
	local width, height = window.get_size()
	if width == context.window_width and height == context.window_height then
		return false
	end

	context.window_width  = width
	context.window_height = height
	
	local scale = math.min(width / context.design_width, height / context.design_height)
	
	gui.set_position(context.content_root, vmath.vector3(width * 0.5, height * 0.5, 0))
	gui.set_scale   (context.content_root, vmath.vector3(scale, scale, 1))
	gui.set_position(context.background,   vmath.vector3(width * 0.5, height * 0.5, 0))
	gui.set_size    (context.background,   vmath.vector3(width, height, 0))
	
	return true
end

return M
