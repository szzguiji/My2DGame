class_name PlayerFollowCamera
extends Camera2D

var _look_ahead: float = 0.0
@onready var player: PlayerController = get_parent()

func _ready() -> void:
	top_level = true
	# Children become ready before their parent's @onready references exist.
	call_deferred("snap_to_player")

func _physics_process(delta: float) -> void:
	var tuning := player.tuning
	_look_ahead = lerpf(_look_ahead,
		DesignUnits.to_pixels(player.movement.facing * tuning.camera_look_ahead),
		1.0 - exp(-tuning.camera_look_ahead_speed * delta))
	var target: Vector2 = player.global_position + Vector2(
		_look_ahead, DesignUnits.to_pixels(tuning.camera_vertical_offset))
	global_position = global_position.lerp(target, 1.0 - exp(-tuning.camera_follow_speed * delta))

func snap_to_player() -> void:
	_look_ahead = DesignUnits.to_pixels(player.movement.facing * player.tuning.camera_look_ahead)
	global_position = player.global_position + Vector2(_look_ahead,
		DesignUnits.to_pixels(player.tuning.camera_vertical_offset))
	reset_physics_interpolation()
	reset_smoothing()
