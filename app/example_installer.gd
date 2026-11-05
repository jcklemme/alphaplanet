class_name ExampleInstaller
extends RefCounted
const TEMPLATE := "res://examples/railgun"
const FILES := ["mod.json", "content.json"]
static func install(root := "user://mods") -> String:
	if DirAccess.make_dir_recursive_absolute(root) != OK:
		return "Error: cannot create local mods folder: " + root
	var destination = root.path_join("experimental_railgun")
	if DirAccess.dir_exists_absolute(destination) or FileAccess.file_exists(destination):
		return "Not installed: destination already exists. Your files were preserved: " + destination
	var staging = root.path_join(".example_install_tmp")
	if DirAccess.dir_exists_absolute(staging):
		return "Error: previous installation staging folder exists; inspect/remove " + staging
	if DirAccess.make_dir_absolute(staging) != OK:
		return "Error: cannot create installation staging folder."
	var success := true
	for name in FILES:
		var bytes = FileAccess.get_file_as_bytes(TEMPLATE.path_join(name))
		var file = FileAccess.open(staging.path_join(name), FileAccess.WRITE)
		if bytes.is_empty() or file == null:
			success = false
			break
		file.store_buffer(bytes)
		if file.get_error() != OK:
			success = false
		file.close()
	if success and DirAccess.rename_absolute(staging, destination) == OK:
		return "Installed example in " + ProjectSettings.globalize_path(destination) + ". Enable it and Apply Changes."
	for name in FILES:
		DirAccess.remove_absolute(staging.path_join(name))
	DirAccess.remove_absolute(staging)
	return "Error: could not install example; existing mods were not changed."
