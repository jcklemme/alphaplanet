class_name DevelopmentTools
extends PanelContainer
var state: CharacterState
var registry: ContentRegistry
var selection: OptionButton
var feedback: Label
var ids: Array[String] = []
static func available() -> bool:
	return OS.is_debug_build()
func entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in registry.all("items"):
		result.append({"id": item.id, "item": item.id, "name": item.name})
	for weapon in registry.all("weapons"):
		result.append({"id": weapon.id, "item": weapon.item, "name": weapon.name + " (weapon)"})
	return result
func grant(id: String) -> bool:
	if not available() or not registry.contains(id):
		return false
	var definition = registry.get_definition(id)
	var item_id: String = definition.item if definition.kind == "weapons" else id
	return state.grant_development_item(item_id)
func _ready() -> void:
	var column = VBoxContainer.new()
	add_child(column)
	var title = Label.new()
	title.text = "DEVELOPMENT ONLY — Grant registered content"
	column.add_child(title)
	selection = OptionButton.new()
	selection.custom_minimum_size.x = 600
	for entry in entries():
		ids.append(entry.id)
		selection.add_item("%s | %s | source: %s" % [entry.name, entry.id, entry.id.get_slice(":", 0)])
	column.add_child(selection)
	var button = Button.new()
	button.text = "Grant Item"
	button.pressed.connect(func():
		var index = selection.selected
		feedback.text = "Granted. Select its equipment group in the sidebar after resuming." if index >= 0 and grant(ids[index]) else "Error: content missing or cannot be instantiated.")
	column.add_child(button)
	feedback = Label.new()
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.text = "Granting is free. New items receive an equipment group."
	column.add_child(feedback)
	var diagnostics = Label.new()
	diagnostics.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var loaded: Array = []
	for mod in registry.enabled:
		loaded.append(mod.id)
	diagnostics.text = "Weapons: %d • Optional mods: %d\nLoaded: %s\n%s" % [registry.all("weapons").size(), maxi(0, loaded.size()-1), str(loaded), "\n".join(registry.diagnostics)]
	column.add_child(diagnostics)
	var back = Button.new()
	back.text = "Back to Pause"
	back.pressed.connect(func(): hide())
	column.add_child(back)
