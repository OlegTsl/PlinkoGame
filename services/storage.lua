local M = {}

function M.create()
	local has_path, path = pcall(sys.get_save_file, "plinko_game", "player")
	local storage = {}

	function storage:load()
		if not has_path then return nil, path end
		local ok, snapshot = pcall(sys.load, path)
		if not ok then return nil, snapshot end
		if type(snapshot) ~= "table" or next(snapshot) == nil then
			return nil, "save does not exist"
		end
		return snapshot
	end

	function storage:save(snapshot)
		if not has_path then return nil, path end
		local ok, result = pcall(sys.save, path, snapshot)
		if not ok or result == false then
			return nil, tostring(result)
		end
		return true
	end

	return storage
end

return M
