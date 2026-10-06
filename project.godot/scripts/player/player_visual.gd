extends Sprite2D
## Placeholder presentation; collider and movement never flip with the sprite.

@onready var player: PlayerController = get_parent()

func _process(_delta: float) -> void:
	flip_h = player.movement.facing < 0
	modulate = Color(0.65, 0.86, 1.0) if player.movement.locomotion == PlayerMovement.Locomotion.AIRBORNE else Color.WHITE
