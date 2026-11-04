class_name HexPlayer
extends Node2D
## Logical movement commits atomically before the presentation animates.
signal action_committed(origin: Vector2i, destination: Vector2i, cost: int)
var hex := Vector2i(3, 9)
var moving := false
var max_health := 20
var health := 20
var melee_damage := 5

func step(grid: HexGrid, destination: Vector2i, size: float) -> bool:
	if moving:
		return false
	var origin = hex
	if not grid.move(self, origin, destination):
		return false
	hex = destination
	moving = true
	action_committed.emit(origin, destination, TurnScheduler.MOVE_COST)
	var tween = create_tween()
	tween.tween_property(self, "position", HexMath.to_world(hex, size), 0.12)
	await tween.finished
	moving = false
	return true

func _draw() -> void:
	draw_circle(Vector2.ZERO, 13, Color("65e7f1"))
	draw_arc(Vector2.ZERO, 17, 0, TAU, 32, Color.WHITE, 2)
	draw_line(Vector2(0, -8), Vector2(0, 8), Color("102b42"), 3)
