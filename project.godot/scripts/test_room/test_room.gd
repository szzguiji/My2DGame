extends Node2D
## Debug test points only: no checkpoints, damage, death or automatic respawn.

@onready var player: PlayerController = $Player
@onready var debug_label: Label = $DebugHUD/Panel/Readout

func _ready() -> void:
	player.reset_for_test($PlayerSpawn.global_position)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_test"):
		player.reset_for_test($PlayerSpawn.global_position)
	if event is InputEventKey and event.pressed and not event.echo:
		var points := {
			KEY_1: $PlayerSpawn, KEY_2: $TestPoints/Coyote,
			KEY_3: $TestPoints/Standard, KEY_4: $TestPoints/NearLimit,
			KEY_5: $TestPoints/Drop
		}
		if points.has(event.keycode):
			player.reset_for_test(points[event.keycode].global_position)

func _process(_delta: float) -> void:
	var movement := player.movement
	var state := "Grounded" if movement.locomotion == PlayerMovement.Locomotion.GROUNDED else "Airborne"
	debug_label.text = ("M1  |  A/D or arrows: move  |  Space: jump  |  R: restart  |  1-5: test points\n"
		+ "%s + None  |  facing %s  |  vx %.2f / vy %.2f DU/s\n"
		+ "Coyote %.3f s  |  Buffer %.3f s  |  last jump: %s  |  release cut: %s\n"
		+ "Height %.2f DU  |  Apex %.2f s  |  g %.2f DU/s²  |  launch %.2f DU/s") % [
		state, "right" if movement.facing > 0 else "left",
		DesignUnits.to_du(player.velocity.x), DesignUnits.to_du(player.velocity.y),
		movement.coyote_remaining, movement.buffer_remaining, movement.last_jump_source,
		movement.jump_cut_applied, player.tuning.jump_height, player.tuning.time_to_apex,
		player.tuning.ascent_gravity(), player.tuning.launch_speed()]

func _draw() -> void:
	# One-DU grid, including the lower safety floor for repeatable fall tests.
	for x in range(-1, 34):
		draw_line(DesignUnits.vector_to_pixels(Vector2(x, -8)),
			DesignUnits.vector_to_pixels(Vector2(x, 14)), Color(0.15, 0.20, 0.25))
	for y in range(-8, 15):
		draw_line(DesignUnits.vector_to_pixels(Vector2(-1, y)),
			DesignUnits.vector_to_pixels(Vector2(33, y)), Color(0.15, 0.20, 0.25))
