class_name AlienStalker
extends Node2D
var hex := Vector2i(21, 12)
var health := 7
var melee_damage := 2
var action_interval := 100

func _draw() -> void:
	draw_circle(Vector2.ZERO, 14, Color("e77781"))
	draw_line(Vector2(-9, -7), Vector2(9, 7), Color.WHITE, 2)
	draw_line(Vector2(-9, 7), Vector2(9, -7), Color.WHITE, 2)
