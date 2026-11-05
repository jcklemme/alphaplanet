extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(description)
func _init() -> void:
	call_deferred("run")
func fixture(id: String, dependencies: Array) -> String:
	var path = "user://menu_mod_tests/" + id
	DirAccess.make_dir_recursive_absolute(path)
	var file = FileAccess.open(path + "/mod.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"id": id, "name": id, "version": "1", "api_version": 1, "dependencies": dependencies}))
	file.close()
	file = FileAccess.open(path + "/content.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema_version": 1, "definitions": []}))
	return path
func run() -> void:
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/menu.tscn", "Startup scene")
	var configuration = ModConfiguration.new()
	configuration.path = "user://test_enabled_mods.json"
	configuration.refresh()
	check(configuration.discovered.any(func(entry): return entry.manifest.id == "example_railgun"), "Railgun discovered through loader")
	check(configuration.enabled.is_empty(), "Optional mods default disabled")
	check(configuration.apply(["example_railgun"]), "Enable applies")
	var reopened = ModConfiguration.new()
	reopened.path = configuration.path
	reopened.read()
	check(reopened.enabled == ["example_railgun"], "Enable persists")
	check(reopened.build(reopened.enabled).contains("example_railgun:weapon"), "Enabled registry contains railgun")
	check(not reopened.apply(["missing_mod"]), "Missing mod configuration rejected")
	check(reopened.enabled == ["example_railgun"], "Failed apply preserves saved selection")
	check(reopened.apply([]) and not reopened.registry.contains("example_railgun:weapon") and reopened.registry.contains("base:pistol_weapon"), "Disable preserves base")
	var dependent = fixture("dependent", ["required"])
	var required = fixture("required", ["base"])
	reopened.sources.assign([dependent, required])
	check(not reopened.apply(["dependent"]), "Cannot enable unsatisfied dependent")
	check(reopened.apply(["dependent", "required"]), "Dependency combination applies")
	check(not reopened.apply(["dependent"]), "Cannot disable required dependency")
	reopened.sources.assign([fixture("cycle_a", ["cycle_b"]), fixture("cycle_b", ["cycle_a"])])
	check(not reopened.apply(["cycle_a", "cycle_b"]), "Cycle rejected")
	var settings = SettingsManager.new()
	settings.path = "user://test_settings.cfg"
	settings.volume = 0.32
	settings.fullscreen = false
	check(settings.save() == OK, "Settings save")
	var next = SettingsManager.new()
	next.path = settings.path
	next.load_settings()
	check(is_equal_approx(next.volume, 0.32) and not next.fullscreen, "Settings persist")
	var menu = load("res://scenes/menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	check(menu.page == "home" and menu.column.get_child_count() == 6, "Five home buttons")
	menu.show_load()
	check(menu.page == "load", "Load placeholder opens")
	menu.show_home()
	menu.show_settings()
	check(menu.page == "settings", "Settings opens")
	menu.show_home()
	check(menu.page == "home", "Back closes settings")
	menu.show_mods()
	menu.show_details({"id": "example_railgun", "name": "Experimental Railgun", "version": "1.0.0", "author": "AlphaPlanet", "dependencies": ["base"]})
	check(menu.details.text.contains("AlphaPlanet") and menu.details.text.contains("base"), "Mod metadata displayed")
	RunManager.start(self)
	await process_frame
	await process_frame
	var game = current_scene
	check(game.player.health == 20 and game.scheduler.world_time == 0, "New run fresh state")
	var event = InputEventKey.new()
	event.physical_keycode = KEY_ESCAPE
	event.pressed = true
	game.route.assign([game.player.hex + Vector2i(1,0)])
	game._unhandled_input(event)
	check(game.route.is_empty() and not paused, "Escape cancels route first")
	game._unhandled_input(event)
	check(paused and game.pause_menu.visible, "Escape pauses")
	var before: Vector2i = game.player.hex
	var move = InputEventKey.new()
	move.physical_keycode = KEY_D
	move.pressed = true
	game._unhandled_input(move)
	check(game.player.hex == before, "Pause blocks input")
	game.pause_menu._input(event)
	check(not paused, "Escape resumes")
	RunManager.end(self)
	await process_frame
	await process_frame
	check(current_scene.page == "home", "Return to main menu")
	print("Menu checks: %d; failures: %d" % [checks, failures])
	current_scene.free()
	quit(0 if failures == 0 else 1)
