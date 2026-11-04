class_name PrototypeHUD
extends CanvasLayer
var label: Label
var inspection: Label
var panel: PanelContainer

func _ready() -> void:
	panel = PanelContainer.new()
	panel.position = Vector2(12, 12)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.035, 0.06, 0.92)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var column = VBoxContainer.new()
	panel.add_child(column)
	label = Label.new()
	column.add_child(label)
	inspection = Label.new()
	inspection.text = "S: examine the hex under the mouse."
	column.add_child(HSeparator.new())
	column.add_child(inspection)

func pointer_over_ui(position: Vector2) -> bool:
	return panel.get_global_rect().has_point(position)

func show_inspection(text: String) -> void:
	inspection.text = text

func update_status(hex: Vector2i, health: int, maximum: int, turns: int, time: int, message: String) -> void:
	label.text = "ALPHAPLANET / PROTOTYPE 0.1c\nQ/E: upper diagonals • A/D: left/right • Z/X: lower diagonals\nS: examine • F: fire (3 damage, range 5) • Space: wait • Esc: cancel\nClick to move / melee • R: restart after Game Over\nHex (%d, %d) • HP %d/%d • Actions %d • Time %d\n%s" % [hex.x, hex.y, health, maximum, turns, time, message]
