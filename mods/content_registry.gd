class_name ContentRegistry
extends RefCounted
const KINDS = ["weapons", "items", "enemies", "skills", "status_effects", "upgrades"]
var _definitions: Dictionary = {}
var diagnostics: Array[String] = []
var enabled: Array[Dictionary] = []

func get_definition(id: String, kind := "") -> Dictionary:
	if not _definitions.has(id) or (not kind.is_empty() and _definitions[id].kind != kind):
		diagnostics.append("Missing content: " + id + " (" + kind + ")")
		return {}
	return _definitions[id].duplicate(true)
func all(kind: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in _definitions:
		if _definitions[id].kind == kind:
			result.append(_definitions[id].duplicate(true))
	return result
func contains(id: String) -> bool:
	return _definitions.has(id)
func snapshot_metadata() -> Dictionary:
	return {"schema_version": 1, "mods": enabled.duplicate(true)}

func register_pack(pack_id: String, document: Variant, dependencies: Array = []) -> bool:
	var error = validate_pack(pack_id, document, dependencies)
	if not error.is_empty():
		diagnostics.append(pack_id + ": " + error)
		return false
	for definition in document.definitions:
		_definitions[definition.id] = definition.duplicate(true)
	return true

func validate_pack(pack_id: String, document: Variant, dependencies: Array) -> String:
	if not document is Dictionary or document.get("schema_version") != 1 or not document.get("definitions") is Array:
		return "Expected schema_version 1 and definitions array"
	var pending: Dictionary = {}
	var id_pattern = RegEx.new()
	id_pattern.compile("^[a-z][a-z0-9_]*:[a-z][a-z0-9_]*$")
	for definition in document.definitions:
		if not definition is Dictionary:
			return "Definition must be an object"
		var id = definition.get("id", "")
		if not id is String or id_pattern.search(id) == null or not id.begins_with(pack_id + ":"):
			return "Invalid or foreign namespaced ID: " + str(id)
		if _definitions.has(id) or pending.has(id):
			return "Duplicate content ID: " + id
		if not KINDS.has(definition.get("kind")) or not definition.get("name") is String or definition.name.is_empty():
			return id + ": invalid kind/name"
		var required: Array = []
		match definition.kind:
			"items": required = ["starting_quantity"]
			"weapons": required = ["damage", "range", "action_cost"]
			"enemies": required = ["health", "damage", "interval", "combat_skill"]
			"skills": required = ["base_value"]
		for field in required:
			if not integer(definition.get(field)):
				return id + ": " + field + " must be an integer"
			if field not in ["combat_skill", "base_value"] and definition[field] < (1 if field in ["health", "interval", "action_cost", "range"] else 0):
				return id + ": invalid " + field
		if definition.has("skill_override") and not integer(definition.skill_override):
			return id + ": skill_override must be an integer"
		if definition.kind in ["status_effects", "upgrades"] and definition.has("description") and not definition.description is String:
			return id + ": description must be text"
		pending[id] = definition
	for definition in pending.values():
		if definition.kind != "weapons":
			continue
		for pair in [["item", "items"], ["skill", "skills"]]:
			var ref = definition.get(pair[0], "")
			if not ref is String:
				return definition.id + ": invalid reference"
			var target: Dictionary = pending.get(ref, _definitions.get(ref, {}))
			if target.get("kind") != pair[1]:
				return definition.id + ": missing " + pair[0] + " reference " + ref
			if ref.get_slice(":", 0) != pack_id and not dependencies.has(ref.get_slice(":", 0)):
				return definition.id + ": undeclared dependency for " + ref
	return ""
static func integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value))
