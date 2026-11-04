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

func update_status(hex: Vector2i, turns: int, message: String) -> void:
	label.text = "ALPHAPLANET / PROTOTYPE 0.1a\nClick a hex to move • Esc cancels route\nKeyboard: E / W / Q / A / S / D (six directions)\nPosition (%d, %d) • Actions %d\n%s" % [hex.x, hex.y, turns, message]
