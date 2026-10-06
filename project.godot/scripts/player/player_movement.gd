class_name PlayerMovement
extends Node
## Locomotion only. Controller owns input/state, presentation reads results.

signal jumped(source: StringName)

enum Locomotion { GROUNDED, AIRBORNE }

var locomotion: Locomotion = Locomotion.AIRBORNE
var facing: int = 1
var coyote_remaining: float = 0.0
var buffer_remaining: float = 0.0
var jump_cut_applied: bool = false
var last_jump_source: StringName = &"none"
var _release_requested: bool = false
var _buffer_released: bool = false
var _fresh_press: bool = false

func press_jump(tuning: PlayerTuning) -> void:
	buffer_remaining = maxf(tuning.jump_buffer, 0.0)
	_fresh_press = true # A zero buffer still accepts a valid immediate press.
	_buffer_released = false

func release_jump() -> void:
	_release_requested = true
	if buffer_remaining > 0.0 or _fresh_press:
		_buffer_released = true

func reset() -> void:
	coyote_remaining = 0.0
	buffer_remaining = 0.0
	_fresh_press = false
	_release_requested = false
	_buffer_released = false
	jump_cut_applied = false
	last_jump_source = &"none"
	locomotion = Locomotion.AIRBORNE
	facing = 1

func step(body: CharacterBody2D, tuning: PlayerTuning, axis: float,
		jump_held: bool, delta: float) -> void:
	var grounded := body.is_on_floor() and body.velocity.y >= 0.0
	if grounded:
		coyote_remaining = maxf(tuning.coyote_time, 0.0)
		jump_cut_applied = false
	if not is_zero_approx(axis):
		facing = 1 if axis > 0.0 else -1
	var rate := tuning.ground_acceleration if grounded else tuning.air_acceleration
	if grounded and is_zero_approx(axis):
		rate = tuning.ground_deceleration
	body.velocity.x = move_toward(body.velocity.x,
		DesignUnits.to_pixels(axis * tuning.max_speed), DesignUnits.to_pixels(rate) * delta)

	if _release_requested:
		_cut_jump(body, tuning)
	_release_requested = false
	if _has_jump_input() and (grounded or coyote_remaining > 0.0):
		_start_jump(body, tuning, jump_held, &"ground" if grounded else &"coyote")

	# Integrate displacement and velocity separately. This avoids the systematic
	# shortfall in jump height from Euler integration at 60 Hz. Split at apex/cap.
	var motion := _vertical_motion(body.velocity.y, tuning, delta)
	var next_vertical_velocity := motion.y
	body.velocity.y = motion.x / delta
	body.move_and_slide()
	if body.is_on_floor() and next_vertical_velocity >= 0.0:
		body.velocity.y = 0.0
		locomotion = Locomotion.GROUNDED
		coyote_remaining = maxf(tuning.coyote_time, 0.0)
		jump_cut_applied = false
		# Consume the buffer on the landing tick; upward motion starts next tick.
		if _has_jump_input():
			_start_jump(body, tuning, jump_held, &"landing_buffer")
	else:
		body.velocity.y = 0.0 if body.is_on_ceiling() and next_vertical_velocity < 0.0 else next_vertical_velocity
		locomotion = Locomotion.AIRBORNE
		coyote_remaining = maxf(0.0, coyote_remaining - delta)
	buffer_remaining = maxf(0.0, buffer_remaining - delta)
	_fresh_press = false

func _has_jump_input() -> bool:
	return _fresh_press or buffer_remaining > 0.0

func _start_jump(body: CharacterBody2D, tuning: PlayerTuning,
		jump_held: bool, source: StringName) -> void:
	body.velocity.y = -DesignUnits.to_pixels(tuning.launch_speed())
	coyote_remaining = 0.0
	buffer_remaining = 0.0
	_fresh_press = false
	jump_cut_applied = false
	locomotion = Locomotion.AIRBORNE
	last_jump_source = source
	# A press/release buffered before landing must retain short-hop intent.
	if _buffer_released or not jump_held:
		_cut_jump(body, tuning)
	_buffer_released = false
	jumped.emit(source)

func _cut_jump(body: CharacterBody2D, tuning: PlayerTuning) -> void:
	if body.velocity.y < 0.0 and not jump_cut_applied:
		body.velocity.y *= clampf(tuning.jump_release_multiplier, 0.0, 1.0)
		jump_cut_applied = true

func _vertical_motion(initial_velocity: float, tuning: PlayerTuning, delta: float) -> Vector2:
	var gravity := DesignUnits.to_pixels(tuning.ascent_gravity())
	var displacement := 0.0
	var remaining := delta
	var speed := initial_velocity
	if speed < 0.0:
		var ascent_time := minf(remaining, -speed / gravity)
		displacement += speed * ascent_time + 0.5 * gravity * ascent_time * ascent_time
		speed += gravity * ascent_time
		remaining -= ascent_time
	if remaining > 0.0:
		gravity *= maxf(tuning.fall_multiplier, 1.0)
		var cap := DesignUnits.to_pixels(maxf(tuning.max_fall_speed, 0.01))
		speed = minf(speed, cap)
		var accelerating_time := minf(remaining, maxf(0.0, (cap - speed) / gravity))
		displacement += speed * accelerating_time + 0.5 * gravity * accelerating_time * accelerating_time
		speed = minf(cap, speed + gravity * accelerating_time)
		displacement += speed * (remaining - accelerating_time)
	return Vector2(displacement, speed)
