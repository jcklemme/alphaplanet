class_name PrototypeHUD
extends CanvasLayer
signal modal_opened
var state: CharacterState
var event_log: GameEventLog
var label: Label
var inspection: Label
var sidebar: PanelContainer
var bottom: PanelContainer
var log_view: RichTextLabel
var quick: VBoxContainer
var group_column: VBoxContainer
var modal: Window
var modal_list: VBoxContainer
var map_container: SubViewportContainer
var map_view: SubViewport
var modal_active := false
var map_size := Vector2(1000, 620)

func _ready() -> void:
	map_container = SubViewportContainer.new()
	map_container.stretch = true
	map_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(map_container)
	map_view = SubViewport.new()
	map_view.handle_input_locally = false
	map_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	map_container.add_child(map_view)
	sidebar = PanelContainer.new()
	add_child(sidebar)
	var column = VBoxContainer.new()
	sidebar.add_child(column)
	var portrait = CharacterPortrait.new()
	portrait.appearance = state.appearance
	portrait.custom_minimum_size = Vector2(240, 85)
	column.add_child(portrait)
	label = Label.new()
	column.add_child(label)
	var header = HBoxContainer.new()
	column.add_child(header)
	var title = Label.new()
	title.text = "Quick Access"
	header.add_child(title)
	button(header, "Inventory", open_inventory)
	var row = HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(row)
	group_column = VBoxContainer.new()
	row.add_child(group_column)
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(scroll)
	quick = VBoxContainer.new()
	quick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(quick)
	inspection = Label.new()
	inspection.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspection.custom_minimum_size.y = 80
	column.add_child(inspection)
	var controls = Label.new()
	controls.text = "Q/E upper • A/D horizontal\nZ/X lower • S examine • F fire\nSpace wait • Esc cancel\nR restart after Game Over"
	column.add_child(controls)
	bottom = PanelContainer.new()
	add_child(bottom)
	log_view = RichTextLabel.new()
	log_view.bbcode_enabled = true
	log_view.scroll_following = true
	bottom.add_child(log_view)
	modal = Window.new()
	modal.title = "Inventory — pin items for quick access"
	modal.size = Vector2i(460, 400)
	modal.exclusive = true
	modal.visible = false
	modal.transient = true
	add_child(modal)
	modal_list = VBoxContainer.new()
	modal_list.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(modal_list)
	modal.close_requested.connect(close_inventory)
	state.changed.connect(refresh_items)
	event_log.changed.connect(refresh_log)
	get_viewport().size_changed.connect(layout)
	layout()
	refresh_items()
	refresh_log()

func button(parent: Node, text: String, action: Callable) -> Button:
	var result = Button.new()
	result.text = text
	result.clip_text = true
	result.custom_minimum_size = Vector2(32, 32)
	result.focus_mode = Control.FOCUS_NONE
	result.pressed.connect(action)
	parent.add_child(result)
	return result
func layout() -> void:
	var size = get_viewport().get_visible_rect().size
	var width = minf(280, size.x * 0.32)
	var height = minf(180, size.y * 0.28)
	map_size = Vector2(size.x-width, size.y-height)
	map_container.size = map_size
	sidebar.position = Vector2(map_size.x, 0)
	sidebar.size = Vector2(width, size.y)
	bottom.position = Vector2(0, map_size.y)
	bottom.size = Vector2(map_size.x, height)
func pointer_over_ui(position: Vector2) -> bool:
	return modal_active or not Rect2(Vector2.ZERO, map_size).has_point(position)
func clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
func refresh_items() -> void:
	clear_children(quick)
	clear_children(group_column)
	clear_children(modal_list)
	for i in state.groups.size():
		button(group_column, ("● " if i == state.active_group else "") + state.groups[i].id, func(): state.activate(i))
	for id in state.ordered_items():
		var item = state.items[id]
		var text = ("★ " if state.pinned.has(id) else "◇ ") + item.name + " ×" + str(item.quantity)
		if state.equipped().has(id):
			text += " [Equipped]"
		if state.selected == id:
			text += " [Selected]"
		button(quick, text, func(): state.selected = id; state.changed.emit())
		button(modal_list, text + " — Pin/unpin", func(): state.toggle_pin(id))
	button(modal_list, "Close", close_inventory)
func open_inventory() -> void:
	modal_active = true
	modal_opened.emit()
	modal.popup_centered()
func close_inventory() -> void:
	modal.hide()
	modal_active = false
func refresh_log() -> void:
	var bar = log_view.get_v_scroll_bar()
	var at_bottom = bar.value >= bar.max_value-bar.page-2
	var old = bar.value
	log_view.clear()
	var colors = {"Combat": "9bd8ff", "Damage": "ffaaaa", "Examination": "d6b5ff", "Movement": "aaccbb", "Items": "ffe0a0", "System": "dddddd"}
	for entry in event_log.entries:
		log_view.append_text("[color=%s][%s] %s[/color]\n" % [colors.get(entry.category, "white"), entry.category, entry.text])
	log_view.scroll_following = at_bottom
	if not at_bottom:
		bar.set_deferred("value", old)
func show_inspection(text: String) -> void:
	inspection.text = text
func update_status(hex: Vector2i, health: int, maximum: int, turns: int, time: int, _message: String) -> void:
	label.text = "%s • HP %d/%d\nEnergy: — (placeholder)\nHex (%d,%d) • Actions %d\nWorld time %d" % [state.name, health, maximum, hex.x, hex.y, turns, time]
