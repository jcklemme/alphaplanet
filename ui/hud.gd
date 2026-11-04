class_name PrototypeHUD
extends CanvasLayer
var label: Label

func _ready() -> void:
	label = Label.new()
	label.position = Vector2(18, 16)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(label)

func update_status(hex: Vector2i, health: int, maximum: int, turns: int, time: int, message: String) -> void:
	label.text = "ALPHAPLANET / PROTOTYPE 0.1b\nQ / E: upper-left / upper-right • A / D: left / right • Z / S: lower-left / lower-right\nClick to move or attack adjacent enemy • Esc: cancel • Space: wait • X: examine\nPosition (%d, %d) • HP %d/%d • Actions %d • World time %d\n%s" % [hex.x, hex.y, health, maximum, turns, time, message]
