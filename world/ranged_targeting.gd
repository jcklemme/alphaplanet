class_name RangedTargeting
extends RefCounted
const WEAPON_NAME := "Basic Energy Pistol"
const DAMAGE := 3
const MAX_RANGE := 5
const COST := 120

static func rejection(grid: HexGrid, origin: Vector2i, target: Vector2i) -> String:
	if not grid.contains(target):
		return "Target is outside the map."
	var enemy = grid.occupants.get(target)
	if not enemy is AlienStalker or enemy.health <= 0:
		return "No living enemy at that hex."
	if HexMath.distance(origin, target) > MAX_RANGE:
		return "Target is beyond pistol range (5 hexes)."
	if not HexSight.clear(grid, origin, target):
		return "A wall blocks the shot."
	return ""
