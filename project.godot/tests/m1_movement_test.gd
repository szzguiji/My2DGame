extends SceneTree
## Run with --headless --path <project> --script res://tests/m1_movement_test.gd
## Exercises real CharacterBody2D collision, not a duplicate movement model.

const PLAYER_SCENE = preload("res://scenes/player/Player.tscn")
const PLATFORM_SCENE = preload("res://scenes/test_room/GrayboxPlatform.tscn")
const ROOM_SCENE = preload("res://scenes/test_room/TestRoom.tscn")
var arena: Node2D
var player: PlayerController
var floor_body: StaticBody2D
var failures: int = 0
var checks: int = 0
var jump_events: Array[StringName] = []
var tick_delta: float = 1.0 / 60.0

func _initialize() -> void:
	# Custom --script SceneTree entry points do not initialize the project map.
	InputMap.load_from_project_settings()
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func _tick(axis: float = 0.0, held: bool = false) -> void:
	await physics_frame
	player.movement.step(player, player.tuning, axis, held, tick_delta)

func _ticks(count: int, axis: float = 0.0, held: bool = false) -> void:
	for i in count:
		await _tick(axis, held)

func _reset(feet: Vector2 = Vector2(0, -0.1)) -> void:
	player.reset_for_test(feet)
	jump_events.clear()
	await _ticks(3)

func _jump_height(release_tick: int = -1) -> Vector2:
	await _reset()
	var start_y := player.position.y
	var minimum_y := start_y
	var apex_tick := 0
	player.movement.press_jump(player.tuning)
	for i in range(int(1.4 / tick_delta)):
		if i == release_tick:
			player.movement.release_jump()
		await _tick(0.0, release_tick < 0 or i < release_tick)
		if player.position.y < minimum_y:
			minimum_y = player.position.y
			apex_tick = i + 1
		if i > 2 and player.movement.locomotion == PlayerMovement.Locomotion.GROUNDED:
			break
	return Vector2(DesignUnits.to_du(start_y - minimum_y), apex_tick * tick_delta)

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	floor_body = PLATFORM_SCENE.instantiate()
	floor_body.position = DesignUnits.vector_to_pixels(Vector2(-50, 0))
	floor_body.size_du = Vector2(100, 2)
	arena.add_child(floor_body)
	player = PLAYER_SCENE.instantiate()
	player.tuning = player.tuning.duplicate()
	arena.add_child(player)
	player.set_physics_process(false)
	player.movement.jumped.connect(func(source: StringName): jump_events.append(source))
	await _reset()
	_check(player.is_on_floor(), "ground detection uses real World collision")
	_check(player.collision_layer == 2 and player.collision_mask == 5,
		"PlayerBody layer 2, mask World + EnemyBody")
	_check(floor_body.collision_layer == 1 and floor_body.collision_mask == 0, "World layer 1")
	for action in ["move_left", "move_right", "jump", "reset_test"]:
		_check(InputMap.has_action(action) and not InputMap.action_get_events(action).is_empty(), "input map: " + action)
	_check(is_equal_approx(player.tuning.ascent_gravity(), 2.0 * 3.25 / (0.36 * 0.36)), "gravity derived from height/apex")
	_check(is_equal_approx(player.tuning.launch_speed(), player.tuning.ascent_gravity() * 0.36), "launch derived from height/apex")
	await _tick(1.0)
	_check(is_equal_approx(DesignUnits.to_du(player.velocity.x), 55.0 / 60.0), "ground acceleration, no speed snap")
	await _ticks(10, 1.0)
	_check(is_equal_approx(DesignUnits.to_du(player.velocity.x), 7.0), "horizontal speed reaches and clamps to 7 DU/s")
	await _tick(0.0)
	_check(is_equal_approx(DesignUnits.to_du(player.velocity.x), 7.0 - 70.0 / 60.0), "ground deceleration 70 DU/s²")
	await _ticks(8)
	_check(is_zero_approx(player.velocity.x), "releasing input stops exactly")
	await _ticks(10, 1.0)
	await _tick(-1.0)
	_check(player.movement.facing == -1 and player.velocity.x > 0.0,
		"facing reverses immediately while velocity reverses through acceleration")
	await _ticks(15, -1.0)
	_check(is_equal_approx(DesignUnits.to_du(player.velocity.x), -7.0), "reversal has no turn lock")
	await _reset()
	player.movement.press_jump(player.tuning)
	await _tick(1.0, true)
	var old_vx := player.velocity.x
	await _tick(-1.0, true)
	_check(is_equal_approx(old_vx - player.velocity.x, DesignUnits.to_pixels(40.0 / 60.0)), "air steering uses 40 DU/s²")

	for hz in [30, 60, 120]:
		Engine.physics_ticks_per_second = hz
		tick_delta = 1.0 / hz
		await physics_frame
		var full := await _jump_height()
		print("MEASURE: %d Hz full height=%.4f DU apex=%.4f s" % [hz, full.x, full.y])
		_check(absf(full.x - 3.25) < 0.025, "%d Hz jump height matches 3.25 DU" % hz)
		_check(absf(full.y - 0.36) <= tick_delta, "%d Hz apex matches 0.36 s within one tick" % hz)
	Engine.physics_ticks_per_second = 60
	tick_delta = 1.0 / 60.0
	await physics_frame
	var full := await _jump_height()
	var short := await _jump_height(3)
	print("MEASURE: held=%.4f DU short=%.4f DU" % [full.x, short.x])
	_check(short.x < full.x * 0.65 and short.x > 0.0, "early release produces a visibly lower jump")
	await _reset()
	player.movement.press_jump(player.tuning)
	await _tick(0.0, true)
	var before_cut := player.velocity.y
	player.movement.release_jump()
	await _tick()
	_check(absf(player.velocity.y - (before_cut * 0.55 + DesignUnits.to_pixels(player.tuning.ascent_gravity()) * tick_delta)) < 0.01,
		"release cuts current upward speed once by 0.55")
	var after_cut := player.velocity.y
	player.movement.release_jump()
	await _tick()
	_check(absf(player.velocity.y - (after_cut + DesignUnits.to_pixels(player.tuning.ascent_gravity()) * tick_delta)) < 0.01,
		"second release cannot cut again")
	await _reset()
	player.movement.press_jump(player.tuning)
	await _tick(0.0, true)
	player.movement.press_jump(player.tuning)
	await _ticks(8, 0.0, true)
	_check(jump_events.size() == 1, "consumed coyote prevents extra airborne jumps")
	await _ticks(55, 0.0, true)
	_check(jump_events.size() == 1, "holding jump does not auto-repeat on landing")

	# Coyote: first walk off a physical edge. No manually granted timers.
	floor_body.size_du = Vector2(50, 2) # right edge at x = 0
	await _reset(Vector2(-16, -0.1))
	for i in 30:
		await _tick(1.0)
		if not player.is_on_floor():
			break
	await _ticks(2)
	player.movement.press_jump(player.tuning)
	await _tick(0.0, true)
	_check(player.velocity.y < 0.0 and jump_events == [&"coyote"], "jump succeeds inside coyote window after actual ledge exit")
	await _reset(Vector2(-16, -0.1))
	for i in 30:
		await _tick(1.0)
		if not player.is_on_floor():
			break
	await _ticks(7)
	player.movement.press_jump(player.tuning)
	await _tick(0.0, true)
	_check(jump_events.is_empty() and player.velocity.y > 0.0, "expired coyote rejects airborne press")

	floor_body.size_du = Vector2(100, 2)
	await _reset(Vector2(0, -18))
	player.movement.press_jump(player.tuning)
	await _ticks(7, 0.0, true)
	_check(jump_events == [&"landing_buffer"], "press before landing launches exactly once on landing")
	await _reset(Vector2(0, -18))
	player.movement.press_jump(player.tuning)
	player.movement.release_jump()
	await _ticks(5)
	_check(jump_events == [&"landing_buffer"] and player.movement.jump_cut_applied,
		"press+release before landing preserves buffered short hop")
	await _reset(Vector2(0, -200))
	player.movement.press_jump(player.tuning)
	await _ticks(60, 0.0, true)
	_check(jump_events.is_empty() and player.is_on_floor(), "stale buffer never launches on later landing")
	await _reset(Vector2(0, -500))
	await _ticks(35)
	_check(is_equal_approx(DesignUnits.to_du(player.velocity.y), 22.0), "fall speed reaches and respects 22 DU/s cap")
	await _ticks(35)
	_check(player.is_on_floor(), "maximum-speed fall lands without tunneling")

	# Ceiling collision clears upward velocity; release cannot relaunch player.
	var ceiling: StaticBody2D = PLATFORM_SCENE.instantiate()
	ceiling.position = Vector2(-64, -90)
	ceiling.size_du = Vector2(4, 0.5)
	arena.add_child(ceiling)
	await _reset()
	player.movement.press_jump(player.tuning)
	await _ticks(8, 0.0, true)
	_check(player.velocity.y >= 0.0 and jump_events.size() == 1, "ceiling hit stops ascent without extra jump")
	ceiling.queue_free()
	await _ticks(2)
	# The same resource drives changed jump parameters at runtime.
	player.tuning.jump_height = 2.5
	player.tuning.time_to_apex = 0.4
	var retuned := await _jump_height()
	_check(absf(retuned.x - 2.5) < 0.025 and absf(retuned.y - 0.4) <= tick_delta,
		"runtime height/apex edits recompute gravity and launch consistently")
	await _reset()
	player.set_physics_process(true)
	_send_action("move_right", true)
	_send_action("jump", true)
	for i in 8:
		await physics_frame
	_check(player.velocity.x > 0.0 and player.position.y < -1.0,
		"real InputEventAction drives controller movement and jump")
	_send_action("jump", false)
	_send_action("move_right", false)
	for i in 2:
		await physics_frame
	_check(player.movement.jump_cut_applied, "controller receives release for variable jump")
	for i in 60:
		await physics_frame
	_check(player.is_on_floor() and is_zero_approx(player.velocity.x) and jump_events.size() == 1,
		"controller input sequence stops, lands, and never repeats jump")
	player.set_physics_process(false)

	arena.queue_free()
	await process_frame
	await _test_room()
	print("M1 RESULTS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _send_action(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)

func _test_room() -> void:
	var room := ROOM_SCENE.instantiate()
	root.add_child(room)
	player = room.get_node("Player")
	player.set_physics_process(false)
	jump_events.clear()
	player.movement.jumped.connect(func(source: StringName): jump_events.append(source))
	await _ticks(3)
	_check(player.is_on_floor(), "TestRoom spawns player on solid ground")
	_check(player.follow_camera.enabled and player.follow_camera.limit_right > player.follow_camera.limit_left,
		"camera active with room limits")
	var camera_before := player.follow_camera.global_position
	await _ticks(30, 1.0)
	_check(player.follow_camera.global_position.x > camera_before.x, "camera follows horizontal movement")
	# Test the actual platform geometry with a full jump and late air correction.
	for point in ["Standard", "NearLimit"]:
		await _reset(room.get_node("TestPoints/" + point).position + Vector2(0, -0.1))
		player.movement.press_jump(player.tuning)
		await _ticks(15, 0.0, true)
		await _ticks(12, 1.0, true)
		await _ticks(22, 0.0, true)
		var target_height := 2.25 if point == "Standard" else 3.15
		_check(player.is_on_floor() and absf(DesignUnits.to_du(player.position.y) + target_height) < 0.01,
			"TestRoom " + point + " platform is reachable from its base")
	await _reset(room.get_node("TestPoints/Drop").position + Vector2(0, -0.1))
	var reached_cap := false
	for i in 120:
		await _tick(1.0 if i < 18 else 0.0)
		if is_equal_approx(DesignUnits.to_du(player.velocity.y), 22.0):
			reached_cap = true
	_check(reached_cap and player.is_on_floor() and absf(player.position.y - 384.0) < 0.1,
		"TestRoom drop reaches cap and lands on non-hazard safety floor")
	player.movement.press_jump(player.tuning)
	player.reset_for_test(room.get_node("PlayerSpawn").position)
	await _ticks(5)
	_check(player.is_on_floor() and player.movement.buffer_remaining == 0.0,
		"debug reset clears pending jump input and stale floor state")
	room.queue_free()
	await process_frame
