@tool
extends StaticBody2D
## Inspector dimensions are DU, collider/visual pixels derive from one source.

@export var size_du: Vector2 = Vector2(2.0, 0.5):
	set(value):
		size_du = Vector2(maxf(value.x, 0.05), maxf(value.y, 0.05))
		if is_node_ready():
			_refresh()
@export var tint: Color = Color(0.27, 0.36, 0.43):
	set(value):
		tint = value
		queue_redraw()

func _ready() -> void:
	_refresh()

func _refresh() -> void:
	var shape := RectangleShape2D.new()
	shape.size = DesignUnits.vector_to_pixels(size_du)
	$CollisionShape2D.shape = shape
	$CollisionShape2D.position = shape.size * 0.5
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, DesignUnits.vector_to_pixels(size_du))
	draw_rect(rect, tint)
	draw_line(rect.position, Vector2(rect.end.x, 0), tint.lightened(0.4), 2.0)
