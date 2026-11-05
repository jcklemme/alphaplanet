class_name ModManager
extends RefCounted
## Only fixed JSON files are read. External paths must be supplied by trusted discovery.
var registry := ContentRegistry.new()
var discovered: Array[Dictionary] = []
var load_order: Array[String] = []

func read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		registry.diagnostics.append("Missing/inaccessible file: " + path)
		return null
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 1048576:
		registry.diagnostics.append("Unreadable or oversized JSON: " + path)
		return null
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		registry.diagnostics.append("Invalid JSON " + path + ": " + json.get_error_message())
		return null
	return json.data

func load_content(external_directories: Array[String] = [], discover_local := true, disabled: Array[String] = [], enabled_only: Variant = null) -> ContentRegistry:
	registry = ContentRegistry.new()
	load_order.clear()
	discovered.clear()
	var paths: Array[String] = ["res://content/base"]
	if discover_local:
		DirAccess.make_dir_recursive_absolute("user://mods")
		var directory = DirAccess.open("user://mods")
		if directory == null:
			registry.diagnostics.append("Cannot access user://mods")
		else:
			for child in directory.get_directories():
				if not directory.is_link(child):
					paths.append("user://mods/" + child)
	paths.append_array(external_directories)
	paths.sort()
	var packs: Dictionary = {}
	var duplicates: Dictionary = {}
	var pattern = RegEx.new()
	pattern.compile("^[a-z][a-z0-9_]*$")
	for path in paths:
		if ".." in path.split("/") or not (path.begins_with("res://") or path.begins_with("user://") or path.is_absolute_path()):
			registry.diagnostics.append("Rejected mod directory: " + path)
			continue
		var directory = DirAccess.open(path)
		if directory == null or directory.is_link("mod.json") or directory.is_link("content.json"):
			registry.diagnostics.append("Inaccessible or linked mod files: " + path)
			continue
		var manifest = read_json(path.path_join("mod.json"))
		if not valid_manifest(manifest, pattern):
			discovered.append({"path": path, "invalid": true, "manifest": {"id": "invalid", "name": path.get_file(), "version": "?", "dependencies": [], "description": "Invalid or unsupported manifest: " + path}})
			registry.diagnostics.append("Invalid manifest: " + path)
			continue
		discovered.append({"path": path, "manifest": manifest.duplicate(true)})
		if manifest.id == "base" and path != "res://content/base":
			registry.diagnostics.append("Reserved mod ID base: " + path)
			continue
		if packs.has(manifest.id):
			duplicates[manifest.id] = true
			registry.diagnostics.append("Duplicate mod ID disabled: " + manifest.id)
		else:
			packs[manifest.id] = {"manifest": manifest, "path": path}
	for id in duplicates:
		packs.erase(id)
	for id in packs.keys():
		if id != "base" and (id in disabled or (enabled_only != null and not enabled_only.has(id))):
			packs.erase(id)
	while not packs.is_empty():
		var progressed := false
		var ids = packs.keys()
		ids.sort()
		for id in ids:
			var pack = packs[id]
			var ready := true
			for dependency in pack.manifest.dependencies:
				if not load_order.has(dependency):
					ready = false
			if not ready:
				continue
			if registry.register_pack(id, read_json(pack.path.path_join("content.json")), pack.manifest.dependencies):
				load_order.append(id)
				registry.enabled.append({"id": id, "version": pack.manifest.version})
			packs.erase(id)
			progressed = true
		if not progressed:
			for id in packs:
				registry.diagnostics.append(id + ": missing, disabled, invalid or cyclic dependencies: " + str(packs[id].manifest.dependencies))
			break
	return registry

func valid_manifest(value: Variant, pattern: RegEx) -> bool:
	if not value is Dictionary:
		return false
	for field in ["id", "name", "version"]:
		if not value.get(field) is String or value[field].is_empty():
			return false
	if pattern.search(value.id) == null or value.get("api_version") != 1 or not value.get("dependencies") is Array:
		return false
	for dependency in value.dependencies:
		if not dependency is String or pattern.search(dependency) == null:
			return false
	for field in ["description", "author"]:
		if value.has(field) and not value[field] is String:
			return false
	return true
