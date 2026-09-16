local M = {
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
}

return M
