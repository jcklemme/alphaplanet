class_name HexInspection
extends RefCounted
static func describe(grid: HexGrid, hex: Vector2i) -> String:
	if not grid.contains(hex):
		return "Outside the map."
	var heading = "Hex (%d, %d)" % [hex.x, hex.y]
	var actor = grid.occupants.get(hex)
	if actor is AlienStalker and actor.health > 0:
		return "%s\nAlien Stalker • HP %d/%d • Melee %d\nA relentless alien hunter." % [heading, actor.health, actor.max_health, actor.melee_damage]
	if actor is HexPlayer:
		return "%s\nPlayer • HP %d/%d" % [heading, actor.health, actor.max_health]
	if grid.blocked.has(hex):
		return heading + "\nWall • Impassable"
	return heading + "\nFloor • Traversable" + (" • Occupied" if actor != null else " • Accessible")
