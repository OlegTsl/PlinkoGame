return {
	balls = {
		count         = 5,
		respawn_delay = 60,
	},

	baskets = {
		items = {
			{ weight = 0.02, score = 100 },
			{ weight = 0.04, score = 50 },
			{ weight = 0.08, score = 20 },
			{ weight = 0.14, score = 10 },
			{ weight = 0.22, score = 5 },
			{ weight = 0.22, score = 5 },
			{ weight = 0.14, score = 10 },
			{ weight = 0.08, score = 20 },
			{ weight = 0.04, score = 50 },
			{ weight = 0.02, score = 100 },
		},
	},

	level = {
		min_basket_count = 5,
		max_basket_count = 10,
	},

	motion = {
		routes_per_bucket     = 8,        -- bounded, continually replenished cache
		work_units_per_frame  = 160,      -- one unit = one local collision sweep
		preparation_budget_ms = 2,
		max_search_candidates = 16000,    -- error with the same target, never reroll
		generator_seed        = 15485863,
	},

	art = {
		ball = { image_size = 40, radius = 12, center_x = 20, center_y = 17 },
		pin  = { image_size = 44, radius = 10, center_x = 22, center_y = 21 },
	},

	runtime = {
		max_active_balls = 32,
		max_visual_step  = 0.05,
	},

	random = {
		weight_epsilon = 1e-9,
		outcome_seed   = 104729,
		visual_seed    = 130363,
	},
}
