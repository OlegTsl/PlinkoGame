local M = {}

function M.create(manager, layout)
	return {
		manager = manager,
		layout  = layout,
	}
end

function M.update(_context, _dt)
end

return M
