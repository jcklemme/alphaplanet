class_name RangedTargeting
extends RefCounted
static func rejection(grid: HexGrid, origin: Vector2i, target: Vector2i, maximum_range: int = 5) -> String:
	if not grid.contains(target):
		return "Target is outside the map."
	var enemy = grid.occupants.get(target)
	if not enemy is AlienStalker or enemy.health <= 0:
		return "No living enemy at that hex."
	if HexMath.distance(origin, target) > maximum_range:
		return "Target is beyond weapon range (%d hexes)." % maximum_range
	if not HexSight.clear(grid, origin, target):
		return "A wall blocks the shot."
	return ""
