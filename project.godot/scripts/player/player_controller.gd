class_name PlayerController
extends CharacterBody2D
## Thin M1 coordinator. No combat/action mechanics are implemented.

enum Action { NONE, ATTACK, DASH, HURT, DEAD }

@export var tuning: PlayerTuning
var action_state: Action = Action.NONE
@onready var movement: PlayerMovement = $Movement
@onready var follow_camera: PlayerFollowCamera = $Camera2D

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") and not event.is_echo():
		movement.press_jump(tuning)
	if event.is_action_released("jump"):
		movement.release_jump()

func _physics_process(delta: float) -> void:
	# M1 only enters None. Future action owners must explicitly coordinate here
	# in priority order Dead > Hurt > Dash > Attack > normal locomotion.
	if action_state == Action.NONE:
		movement.step(self, tuning, Input.get_axis("move_left", "move_right"),
			Input.is_action_pressed("jump"), delta)

func reset_for_test(feet_position: Vector2) -> void:
	global_position = feet_position
	velocity = Vector2.ZERO
	action_state = Action.NONE
	movement.reset()
	# Refresh CharacterBody2D's cached floor contacts after a debug teleport.
	move_and_slide()
	follow_camera.snap_to_player()
