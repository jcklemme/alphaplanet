extends Control
var settings := SettingsManager.new()
var configuration := ModConfiguration.new()
var column: VBoxContainer
var page := ""
var desired: Array[String] = []
var details: Label
var status: Label
var list: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings.load_settings()
	configuration.read()
	var background = ColorRect.new()
	background.color = Color("101b29")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 36)
	add_child(margin)
	column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	show_home()
func clear(title: String) -> void:
	for child in column.get_children():
		column.remove_child(child)
		child.queue_free()
	var heading = Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 34)
	heading.add_theme_color_override("font_color", Color("79d7e3"))
	column.add_child(heading)
func button(parent: Node, text: String, action: Callable) -> Button:
	var control = Button.new()
	control.text = text
	control.custom_minimum_size.y = 44
	control.pressed.connect(action)
	parent.add_child(control)
	return control
func label(parent: Node, text: String) -> Label:
	var result = Label.new()
	result.text = text
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(result)
	return result
func show_home() -> void:
	page = "home"
	clear("ALPHAPLANET")
	button(column, "New Run", func(): RunManager.start(get_tree()))
	button(column, "Load Run", show_load)
	button(column, "Mod Manager", show_mods)
	button(column, "Settings", show_settings)
	button(column, "Exit Game", exit_game)
func exit_game() -> void:
	get_tree().quit()
func show_load() -> void:
	page = "load"
	clear("Load Run")
	label(column, "Run saving and loading is not yet implemented.")
	button(column, "Back", show_home)
func show_settings() -> void:
	page = "settings"
	clear("Settings")
	label(column, "Master volume")
	var slider = HSlider.new()
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.01
	slider.value = settings.volume
	column.add_child(slider)
	var toggle = CheckButton.new()
	toggle.text = "Fullscreen"
	toggle.button_pressed = settings.fullscreen
	column.add_child(toggle)
	var feedback = label(column, "Changes save immediately.")
	slider.value_changed.connect(func(value): settings.volume = value; feedback.text = "Saved" if settings.save() == OK else "Could not save settings")
	toggle.toggled.connect(func(value): settings.fullscreen = value; feedback.text = "Saved" if settings.save() == OK else "Could not save settings")
	button(column, "Back", show_home)
func show_mods() -> void:
	page = "mods"
	configuration.refresh()
	desired = configuration.enabled.duplicate()
	clear("Local Mod Manager")
	var row = HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(row)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.x = 470
	row.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var info_scroll = ScrollContainer.new()
	info_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info_scroll)
	details = label(info_scroll, "Select a mod for metadata and diagnostics.")
	details.custom_minimum_size.x = 550
	for entry in configuration.discovered:
		var manifest = entry.manifest
		var item = HBoxContainer.new()
		list.add_child(item)
		var toggle = CheckBox.new()
		toggle.button_pressed = manifest.id == "base" or desired.has(manifest.id)
		toggle.disabled = manifest.id == "base" or entry.get("invalid", false)
		item.add_child(toggle)
		toggle.toggled.connect(func(value):
			if value and not desired.has(manifest.id): desired.append(manifest.id)
			elif not value: desired.erase(manifest.id)
			status.text = "Pending changes. Apply validates dependencies before saving.")
		button(item, manifest.name + " " + manifest.version + (" [ERROR]" if entry.get("invalid", false) else "") + "\n" + manifest.get("author", "Unknown author") + " • Dependencies: " + str(manifest.dependencies) + "\n" + manifest.get("description", ""), func(): show_details(manifest))
	status = label(column, "\n".join(configuration.diagnostics) if not configuration.diagnostics.is_empty() else "Base is required. New optional mods default to disabled.")
	button(column, "Apply Changes", apply_mods)
	button(column, "Refresh Mods (discard pending changes)", show_mods)
	button(column, "Open Mods Folder", open_folder)
	button(column, "Back", show_home)
func show_details(manifest: Dictionary) -> void:
	var trial = configuration.build(desired)
	var active := false
	for entry in trial.enabled:
		if entry.id == manifest.id: active = true
	details.text = "%s\nID: %s\nVersion: %s\nAuthor: %s\n%s\nDependencies: %s\nDesired: %s\nValidation: %s\n%s" % [manifest.name, manifest.id, manifest.version, manifest.get("author", "—"), manifest.get("description", ""), str(manifest.dependencies), "enabled" if manifest.id == "base" or desired.has(manifest.id) else "disabled", "loaded" if active else "disabled or failed", "\n".join(configuration.diagnostics + trial.diagnostics)]
func apply_mods() -> void:
	if configuration.apply(desired):
		status.text = "Applied and saved. The next New Run uses this configuration." + ("\n" + "\n".join(configuration.diagnostics) if not configuration.diagnostics.is_empty() else "")
	else:
		status.text = "Not applied. Resolve dependencies/errors:\n" + "\n".join(configuration.diagnostics)
func open_folder() -> void:
	var error = DirAccess.make_dir_recursive_absolute("user://mods")
	if error == OK:
		error = OS.shell_open(ProjectSettings.globalize_path("user://mods"))
	status.text = "Mods folder opened." if error == OK else "Could not open folder: " + ProjectSettings.globalize_path("user://mods")
