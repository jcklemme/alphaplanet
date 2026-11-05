class_name PauseMenu
extends CanvasLayer
signal resumed
var panel: PanelContainer
var state: CharacterState
var registry: ContentRegistry
var tools_panel: DevelopmentTools
func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel = PanelContainer.new()
	panel.position = Vector2(340, 240)
	panel.size = Vector2(600, 260)
	add_child(panel)
	var column = VBoxContainer.new()
	panel.add_child(column)
	var title = Label.new()
	title.text = "PAUSED\nReturning to Main Menu discards this run. No run save exists."
	column.add_child(title)
	var resume = Button.new()
	resume.text = "Resume"
	resume.pressed.connect(close)
	column.add_child(resume)
	var leave = Button.new()
	leave.text = "Discard Run and Return to Main Menu"
	leave.pressed.connect(func(): RunManager.end(get_tree()))
	column.add_child(leave)
	if DevelopmentTools.available():
		var tools_button = Button.new()
		tools_button.text = "Development Tools"
		tools_button.pressed.connect(open_tools)
		column.add_child(tools_button)
	hide()
func open_tools() -> void:
	if not DevelopmentTools.available():
		return
	if tools_panel == null:
		tools_panel = DevelopmentTools.new()
		tools_panel.state = state
		tools_panel.registry = registry
		tools_panel.position = Vector2(280, 220)
		add_child(tools_panel)
	tools_panel.show()
func open() -> void:
	show()
	get_tree().paused = true
func close() -> void:
	if tools_panel != null:
		tools_panel.hide()
	get_tree().paused = false
	hide()
	resumed.emit()
func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("cancel_route") and not event.is_echo():
		close()
		get_viewport().set_input_as_handled()
