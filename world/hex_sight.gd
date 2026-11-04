class_name HexSight
extends RefCounted
## Canonical endpoint order and a fixed cube nudge resolve edge ties symmetrically.
static func line(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	if a.x > b.x or (a.x == b.x and a.y > b.y):
		var reversed = line(b, a)
		reversed.reverse()
		return reversed
	var result: Array[Vector2i] = []
	var count = HexMath.distance(a, b)
	for i in range(count + 1):
		var t = float(i) / maxi(count, 1)
		var q = lerpf(a.x, b.x, t) + 0.000001
		var r = lerpf(a.y, b.y, t) + 0.000001
		var s = -q-r
		var rounded = Vector3(round(q), round(r), round(s))
		var error = Vector3(abs(rounded.x-q), abs(rounded.y-r), abs(rounded.z-s))
		if error.x > error.y and error.x > error.z:
			rounded.x = -rounded.y-rounded.z
		elif error.y > error.z:
			rounded.y = -rounded.x-rounded.z
		result.append(Vector2i(int(rounded.x), int(rounded.y)))
	return result

static func clear(grid: HexGrid, a: Vector2i, b: Vector2i) -> bool:
	for hex in line(a, b):
		if not grid.contains(hex) or grid.blocked.has(hex):
			return false
	return true
