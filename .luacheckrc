std = "luajit"
max_line_length = 120
unused_args = false -- Defold callbacks and colon methods have fixed signatures.
exclude_files = { ".deps/**", ".internal/**", "build/**" }

-- Pure model/manager/controller modules deliberately have no engine globals.
files["view/*.lua"] = {
	read_globals = { "gui", "vmath", "hash", "msg", "window", "imgui", "sound" },
}
files["services/*.lua"] = { read_globals = { "sys" } }
files["config/build_config.lua"] = { read_globals = { "sys" } }
files["main/*.gui_script"] = {
	read_globals = { "gui", "vmath", "hash", "msg", "window", "sys" },
	globals = { "init", "update", "on_input", "final" },
}
files["render/*.render_script"] = {
	read_globals = { "render", "graphics", "camera", "vmath", "hash", "sys" },
	globals = { "init", "update", "on_message" },
}
