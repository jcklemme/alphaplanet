class_name HexMath
extends RefCounted
## Pointy-top axial coordinates. All world conversion lives here.
const DIRECTIONS = [Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)]

static func to_world(hex: Vector2i, size: float) -> Vector2:
	return Vector2(sqrt(3.0) * size * (hex.x + hex.y / 2.0), 1.5 * size * hex.y)

static func from_world(point: Vector2, size: float) -> Vector2i:
	var q = (sqrt(3.0) / 3.0 * point.x - point.y / 3.0) / size
	var r = 2.0 / 3.0 * point.y / size
	var s = -q - r
	var rounded = Vector3(round(q), round(r), round(s))
	var error = Vector3(abs(rounded.x - q), abs(rounded.y - r), abs(rounded.z - s))
	if error.x > error.y and error.x > error.z:
		rounded.x = -rounded.y - rounded.z
	elif error.y > error.z:
		rounded.y = -rounded.x - rounded.z
	return Vector2i(int(rounded.x), int(rounded.y))

static func distance(a: Vector2i, b: Vector2i) -> int:
	var d = a - b
	return maxi(maxi(abs(d.x), abs(d.y)), abs(d.x + d.y))

static func neighbors(hex: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for direction in DIRECTIONS:
		result.append(hex + direction)
	return result
