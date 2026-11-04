class_name HexGrid
extends RefCounted
## Logical terrain and occupancy; no scene or pixel dependencies.
var width: int
var height: int
var blocked: Dictionary = {}
var occupants: Dictionary = {}

func _init(columns: int = 30, rows: int = 20) -> void:
	width = columns
	height = rows

func contains(hex: Vector2i) -> bool:
	return hex.x >= 0 and hex.x < width and hex.y >= 0 and hex.y < height

func is_open(hex: Vector2i) -> bool:
	return contains(hex) and not blocked.has(hex) and not occupants.has(hex)

func place(actor: Object, hex: Vector2i) -> bool:
	if not is_open(hex) or occupants.values().has(actor):
		return false
	occupants[hex] = actor
	return true

func can_move(actor: Object, origin: Vector2i, destination: Vector2i) -> bool:
	return occupants.get(origin) == actor and actor != null and HexMath.distance(origin, destination) == 1 and is_open(destination)

func move(actor: Object, origin: Vector2i, destination: Vector2i) -> bool:
	if not can_move(actor, origin, destination):
		return false
	occupants.erase(origin)
	occupants[destination] = actor
	return true
