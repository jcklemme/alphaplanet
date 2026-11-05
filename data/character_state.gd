class_name CharacterState
extends RefCounted
signal changed
var name := "Explorer"
var skills := {"ranged": 12, "melee": 11}
var anatomy: Array[Dictionary] = []
var appearance := {"body_parts": [], "equipment": [], "layers": [{"id": "body", "color": Color("65e7f1")}]}
var registry: ContentRegistry
var items: Dictionary = {}
var pinned: Array[String] = []
var selected := "pistol"
var groups: Array[Dictionary] = [{"id": "1", "equipped": ["pistol"]}, {"id": "2", "equipped": ["knife"]}, {"id": "3", "equipped": []}]
var active_group := 0
func _init(content: ContentRegistry = null) -> void:
	registry = content if content != null else ModManager.new().load_content([], false)
	for category in ["ranged", "melee"]:
		skills[category] = int(registry.get_definition("base:" + category, "skills").base_value)
	for definition in registry.all("items"):
		if definition.starting_quantity > 0 and definition.id.begins_with("base:"):
			items[definition.id.get_slice(":", 1)] = {"content_id": definition.id, "quantity": int(definition.starting_quantity)}
	for id in ["head", "torso", "left_arm", "right_arm", "left_leg", "right_leg"]:
		anatomy.append({"id": id, "condition": 1.0, "injuries": [], "armor": [], "replacement": "", "mutations": [], "impairment": 0.0})
func equipped() -> Array:
	return groups[active_group].equipped
func activate(index: int) -> void:
	if index >= 0 and index < groups.size():
		active_group = index
		changed.emit()
func toggle_pin(id: String) -> void:
	if not items.has(id):
		return
	if pinned.has(id):
		pinned.erase(id)
	else:
		pinned.append(id)
	changed.emit()
func ordered_items() -> Array:
	var result: Array = pinned.duplicate()
	for id in items:
		if not result.has(id):
			result.append(id)
	return result

func item_view(instance_id: String) -> Dictionary:
	if not items.has(instance_id):
		return {}
	var definition = registry.get_definition(items[instance_id].content_id, "items")
	if definition.is_empty():
		return {"name": "Missing: " + items[instance_id].content_id, "quantity": items[instance_id].quantity}
	definition.quantity = items[instance_id].quantity
	return definition

func active_ranged_weapon() -> Dictionary:
	for instance_id in equipped():
		if not items.has(instance_id):
			continue
		for weapon in registry.all("weapons"):
			if weapon.item == items[instance_id].content_id and weapon.skill == "base:ranged":
				return weapon
	return {}

func grant_development_item(content_id: String) -> bool:
	if not registry.contains(content_id) or registry.get_definition(content_id).kind != "items":
		return false
	items[content_id] = {"content_id": content_id, "quantity": 1}
	groups.append({"id": str(groups.size()+1), "equipped": [content_id]})
	changed.emit()
	return true
