extends SceneTree
var failures := 0
var checks := 0
func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(description)
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var config = ModConfiguration.new()
	config.local_root = "user://install_test_" + str(Time.get_ticks_usec())
	config.path = config.local_root + "/selection.json"
	config.refresh()
	check(DirAccess.dir_exists_absolute(config.local_root), "Missing local root created")
	check(config.discovered.size() == 1, "Empty local root only has base")
	check(ExampleInstaller.install(config.local_root).begins_with("Installed"), "Example installs")
	var destination = config.local_root + "/experimental_railgun"
	check(FileAccess.file_exists(destination + "/mod.json") and FileAccess.file_exists(destination + "/content.json"), "Actual files installed")
	var original = FileAccess.get_file_as_string(destination + "/content.json")
	check(ExampleInstaller.install(config.local_root).contains("preserved") and FileAccess.get_file_as_string(destination + "/content.json") == original, "Repeat install does not overwrite")
	config.refresh()
	check(config.discovered.size() == 2 and config.discovered[1].source == "Local Mod", "Local source discovery")
	check(config.apply(["example_railgun"]), "Local example enabled")
	var reopened = ModConfiguration.new()
	reopened.local_root = config.local_root
	reopened.path = config.path
	reopened.read()
	check(reopened.enabled == ["example_railgun"], "Persisted selection reloads")
	var game = load("res://scenes/main.tscn").instantiate()
	game.configuration_override = reopened
	root.add_child(game)
	var tools = DevelopmentTools.new()
	tools.state = game.player.state
	tools.registry = game.content
	game.add_child(tools)
	check(tools.entries().any(func(entry): return entry.id == "example_railgun:weapon"), "Dynamic weapon list from active run")
	game.pause_menu.open()
	game.pause_menu.open_tools()
	check(game.pause_menu.tools_panel.visible, "Pause tools accessible")
	check(tools.grant("example_railgun:weapon"), "Grant weapon through existing inventory")
	check(game.player.state.items.has("example_railgun:railgun") and game.scheduler.world_time == 0, "Grant updates inventory without time")
	check(tools.grant("example_railgun:railgun") and game.player.state.items["example_railgun:railgun"].quantity == 2 and game.player.state.groups.size() == 4, "Repeat grant stacks without duplicate group")
	game.player.state.activate(3)
	game.pause_menu.close()
	var enemy = game.enemies[0]
	game.grid.occupants.erase(enemy.hex)
	enemy.hex = game.player.hex + Vector2i(7,0)
	game.grid.occupants[enemy.hex] = enemy
	enemy.health = 30
	game.die = func(): return 6
	check(game.fire_at(enemy.hex) and enemy.health == 30 and game.scheduler.world_time == 180, "Failed 3d6 shot spends defined cost, no damage")
	await create_timer(0.2).timeout
	game.die = func(): return 3
	var weapon = game.player.state.active_ranged_weapon()
	check(weapon.range == 9 and weapon.skill_override == 10, "Range and accuracy from local JSON")
	check(game.fire_at(enemy.hex) and enemy.health == 18 and game.scheduler.world_time == 360, "Successful local Railgun hit deals 12 once")
	await create_timer(0.2).timeout
	game.free()
	check(config.apply([]), "Disable applies")
	var disabled = config.build([])
	tools = DevelopmentTools.new()
	tools.registry = disabled
	check(not tools.entries().any(func(entry): return entry.id.begins_with("example_railgun:")) and disabled.contains("base:pistol_weapon"), "Disabled item absent, base intact")
	tools.free()
	# A second genuinely installed copy must be rejected.
	var duplicate = config.local_root + "/duplicate"
	DirAccess.make_dir_absolute(duplicate)
	for name in ExampleInstaller.FILES:
		DirAccess.copy_absolute(destination + "/" + name, duplicate + "/" + name)
	check(not config.apply(["example_railgun"]) and str(config.diagnostics).contains("Duplicate"), "Installed duplicate rejected")
	for directory in [duplicate, destination]:
		for name in ExampleInstaller.FILES:
			DirAccess.remove_absolute(directory + "/" + name)
		DirAccess.remove_absolute(directory)
	var absent = config.build(["example_railgun"])
	check(absent.contains("base:pistol_weapon") and str(absent.diagnostics).contains("did not load"), "Removed installed mod safe")
	DirAccess.remove_absolute(config.path)
	DirAccess.remove_absolute(config.local_root)
	print("Local installation checks: %d; failures: %d" % [checks, failures])
	quit(0 if failures == 0 else 1)
