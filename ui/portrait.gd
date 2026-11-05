class_name CharacterPortrait
extends Control
var appearance: Dictionary
func _draw() -> void:
	var color: Color = appearance.layers[0].color
	draw_circle(Vector2(110, 26), 18, color)
	draw_rect(Rect2(82, 48, 56, 32), color.darkened(0.3))
