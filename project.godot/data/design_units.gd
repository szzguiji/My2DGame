class_name DesignUnits
extends RefCounted
## The only DU conversion: Godot v2.0 specification, 1 DU = 32 pixels.

const PIXELS_PER_DU: float = 32.0

static func to_pixels(value: float) -> float:
	return value * PIXELS_PER_DU

static func to_du(value: float) -> float:
	return value / PIXELS_PER_DU

static func vector_to_pixels(value: Vector2) -> Vector2:
	return value * PIXELS_PER_DU
