class_name HexBoard
extends Node2D
const SIZE := 28.0
var grid: HexGrid
var hover := Vector2i(-1, -1)
var route: Array[Vector2i] = []

func _draw() -> void:
	if grid == null:
		return
	for r in grid.height:
		for q in grid.width:
			var hex = Vector2i(q, r)
			var center = HexMath.to_world(hex, SIZE)
			var corners = PackedVector2Array()
			for i in 6:
				corners.append(center + Vector2.from_angle(deg_to_rad(60 * i - 30)) * (SIZE - 1))
			var color = Color("172d40")
			if grid.blocked.has(hex):
				color = Color("596579")
			elif route.has(hex):
				color = Color("266c76")
			if hex == hover:
				color = color.lightened(0.3)
			draw_colored_polygon(corners, color)
			corners.append(corners[0])
			draw_polyline(corners, Color("30495b"), 1)
