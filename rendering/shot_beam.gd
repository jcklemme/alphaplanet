class_name ShotBeam
extends Node2D
var destination: Vector2
func _ready() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	tween.tween_callback(queue_free)
func _draw() -> void:
	draw_line(Vector2.ZERO, destination, Color("7df6ff"), 3.0, true)
