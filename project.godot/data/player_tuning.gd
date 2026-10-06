class_name PlayerTuning
extends Resource
## All gameplay distances/speeds use DU; time uses seconds.
## Derived gravity/launch speed are read-only, never a second tuning source.

@export_group("Horizontal movement (DU)")
@export_range(0.1, 20.0, 0.1) var max_speed: float = 7.0
@export_range(0.1, 150.0, 0.5) var ground_acceleration: float = 55.0
@export_range(0.1, 150.0, 0.5) var ground_deceleration: float = 70.0
@export_range(0.1, 150.0, 0.5) var air_acceleration: float = 40.0

@export_group("Jump (DU and seconds)")
@export_range(0.1, 10.0, 0.05) var jump_height: float = 3.25
@export_range(0.05, 2.0, 0.01) var time_to_apex: float = 0.36
@export_range(1.0, 4.0, 0.05) var fall_multiplier: float = 1.5
@export_range(0.05, 1.0, 0.01) var jump_release_multiplier: float = 0.55
@export_range(0.1, 60.0, 0.5) var max_fall_speed: float = 22.0
@export_range(0.0, 0.3, 0.01) var coyote_time: float = 0.10
@export_range(0.0, 0.3, 0.01) var jump_buffer: float = 0.10

@export_group("Minimal camera")
@export_range(0.1, 40.0, 0.5) var camera_follow_speed: float = 12.0
@export_range(0.0, 2.0, 0.05) var camera_look_ahead: float = 0.65
@export_range(0.1, 40.0, 0.5) var camera_look_ahead_speed: float = 8.0
@export_range(-3.0, 1.0, 0.05) var camera_vertical_offset: float = -1.0

func ascent_gravity() -> float:
	return 2.0 * maxf(jump_height, 0.01) / pow(maxf(time_to_apex, 0.01), 2.0)

func launch_speed() -> float:
	return ascent_gravity() * maxf(time_to_apex, 0.01)
