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

	physics = {
		gravity_ratio = 16,               -- logical basket widths / s²
		ball_radius_ratio = 0.20,
		pin_restitution = 0.78,
		wall_restitution = 0.86,
		divider_restitution = 0.55,
		tangent_retention = 0.995,
		spawn_spread_ratio = 0.22,         -- initial offset only; no airborne steering
		launch_vx_ratio = 5.0,
		launch_vy_min_ratio = -1.0,
		launch_vy_max_ratio = -0.2,
		contact_horizon = 0.20,           -- broad-phase sweep, independent of FPS
		root_epsilon = 1e-10,
		root_iterations = 48,
		time_epsilon = 1e-8,
		velocity_epsilon_ratio = 1e-7,
		max_flight_time = 16,
		max_contacts = 96,
		minimum_pin_hits = 2,
	},

	motion = {
		routes_per_bucket = 8,            -- bounded, continually replenished cache
		work_units_per_frame = 160,       -- one unit = one local collision sweep
		preparation_budget_ms = 2,
		max_search_candidates = 16000,    -- error with the same target, never reroll
		generator_seed = 15485863,
	},

	art = {
		ball = { image_size = 40, radius = 12, center_x = 20, center_y = 17 },
		pin = { image_size = 44, radius = 10, center_x = 22, center_y = 21 },
	},

	runtime = {
		max_active_balls = 32,
		max_visual_step  = 0.05,
	},

	ui = {
		wave = {
			duration    = 0.30,
			start_scale = 1,
			end_scale   = 4,
			start_alpha = 0.35,
			pool_size = 128,
		},
		pop = {
			max_scale    = 1.6,
			up_duration  = 0.10,
			down_duration = 0.16,
		},
	},

	random = {
		weight_epsilon = 1e-9,
		outcome_seed = 104729,
		visual_seed  = 130363,
	},
}
