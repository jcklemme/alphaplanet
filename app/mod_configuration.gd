class_name ModConfiguration
extends RefCounted
var path := "user://enabled_mods.json"
var sources: Array[String] = []
var local_root := "user://mods"
var enabled: Array[String] = []
var discovered: Array[Dictionary] = []
var diagnostics: Array[String] = []
var registry: ContentRegistry

func read() -> void:
	enabled.clear()
	if not FileAccess.file_exists(path):
		return
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		diagnostics.append("Cannot read mod configuration")
		return
	var value = JSON.parse_string(file.get_as_text())
	if not value is Dictionary or value.get("version") != 1 or not value.get("enabled") is Array:
		diagnostics.append("Invalid mod configuration; optional mods disabled")
		return
	for id in value.enabled:
		if id is String and id != "base" and not enabled.has(id):
			enabled.append(id)

func refresh() -> void:
	var manager = ModManager.new()
	manager.local_root = local_root
	manager.load_content(sources)
	discovered = manager.discovered
	diagnostics = manager.registry.diagnostics.duplicate()

func build(ids: Array[String]) -> ContentRegistry:
	var manager = ModManager.new()
	manager.local_root = local_root
	var result = manager.load_content(sources, true, [], ids)
	for id in ids:
		if not manager.load_order.has(id):
			result.diagnostics.append("Requested mod did not load: " + id)
	return result

func apply(ids: Array[String]) -> bool:
	var candidate = build(ids)
	var loaded: Array = []
	for mod in candidate.enabled:
		loaded.append(mod.id)
	for id in ids:
		if not loaded.has(id):
			diagnostics = candidate.diagnostics.duplicate()
			return false
	if not loaded.has("base"):
		diagnostics = candidate.diagnostics.duplicate()
		return false
	var file = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		diagnostics = ["Cannot save mod configuration"]
		return false
	file.store_string(JSON.stringify({"version": 1, "enabled": ids}))
	file.close()
	if DirAccess.rename_absolute(path + ".tmp", path) != OK:
		diagnostics = ["Cannot replace mod configuration"]
		return false
	enabled = ids.duplicate()
	registry = candidate
	diagnostics = candidate.diagnostics.duplicate()
	return true
