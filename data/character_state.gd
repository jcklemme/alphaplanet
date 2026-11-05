class_name CharacterState
extends RefCounted
signal changed
var name := "Explorer"
var skills := {"ranged": 12, "melee": 11}
var anatomy: Array[Dictionary] = []
var appearance := {"body_parts": [], "equipment": [], "layers": [{"id": "body", "color": Color("65e7f1")}]}
var items := {
	"pistol": {"name": "Plasma Pistol", "quantity": 1, "skill": "ranged"},
	"knife": {"name": "Combat Knife", "quantity": 1, "skill": "melee"},
	"med": {"name": "Med Injector", "quantity": 2},
	"frag": {"name": "Frag Grenade", "quantity": 1},
	"stim": {"name": "Stim Pack", "quantity": 3}}
var pinned: Array[String] = []
var selected := "pistol"
var groups: Array[Dictionary] = [{"id": "1", "equipped": ["pistol"]}, {"id": "2", "equipped": ["knife"]}, {"id": "3", "equipped": []}]
var active_group := 0
func _init() -> void:
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
