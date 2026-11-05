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
func write_json(path: String, value: Variant) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value))
func fixture(id: String, dependencies: Array, document: Variant) -> String:
	var path = "user://mod_tests/" + id
	DirAccess.make_dir_recursive_absolute(path)
	write_json(path + "/mod.json", {"id": id, "name": id, "version": "1", "api_version": 1, "dependencies": dependencies})
	write_json(path + "/content.json", document)
	return path
func run() -> void:
	var manager = ModManager.new()
	var registry = manager.load_content(["res://examples/railgun"], false)
	check(registry.get_definition("base:pistol_weapon").damage == 3, "Base pistol data")
	check(registry.get_definition("base:knife_weapon").damage == 5 and registry.get_definition("base:med").starting_quantity == 2, "Knife and med data")
	check(registry.get_definition("base:stalker").health == 7, "Stalker data")
	check(manager.load_order == ["base", "example_railgun"], "Dependency order")
	var copy = registry.get_definition("base:pistol_weapon")
	copy.damage = 999
	check(registry.get_definition("base:pistol_weapon").damage == 3, "Definition copies immutable to callers")
	var duplicate = {"schema_version": 1, "definitions": [registry.get_definition("base:pistol")]}
	check(not registry.register_pack("base", duplicate), "Duplicate ID rejected")
	check(registry.diagnostics.back().contains("Duplicate"), "Duplicate diagnostic")
	var atomic = {"schema_version": 1, "definitions": [{"id": "atomic:good", "kind": "items", "name": "Good", "starting_quantity": 0}, {"id": "atomic:bad", "kind": "weapons", "name": "Bad", "damage": 1, "range": 1, "action_cost": 1, "item": "atomic:missing", "skill": "base:ranged"}]}
	check(not registry.register_pack("atomic", atomic, ["base"]) and not registry.contains("atomic:good"), "Atomic reference failure")
	manager.load_content(["relative/../bad", "/tmp/alphaplanet-nonexistent-mod"], false)
	check(str(manager.registry.diagnostics).contains("Rejected") and str(manager.registry.diagnostics).contains("Inaccessible"), "Invalid paths diagnosed")
	var bad = fixture("bad", [], {"schema_version": 1, "definitions": [{"id": "bad:item", "kind": "items", "name": "Bad", "starting_quantity": -1}]})
	var missing = fixture("missing", ["absent"], {"schema_version": 1, "definitions": []})
	var broken = fixture("broken", [], {})
	var file = FileAccess.open(broken + "/content.json", FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	var a = fixture("a", ["base"], {"schema_version": 1, "definitions": []})
	var b = fixture("b", ["a"], {"schema_version": 1, "definitions": []})
	var paths: Array[String] = [b, missing, bad, broken, a]
	registry = manager.load_content(paths, false)
	check(not registry.contains("bad:item"), "Invalid pack disabled")
	check(str(registry.diagnostics).contains("Invalid JSON") and str(registry.diagnostics).contains("dependencies"), "Invalid JSON and dependencies diagnosed")
	var order = manager.load_order.duplicate()
	paths.reverse()
	manager.load_content(paths, false)
	check(manager.load_order == order and order.find("a") < order.find("b"), "Discovery order does not change load order")
	registry = manager.load_content(["res://examples/railgun"], false, ["example_railgun"])
	check(not registry.contains("example_railgun:weapon") and registry.contains("base:pistol_weapon"), "Disabled mod leaves base intact")
	check(registry.get_definition("missing:item").is_empty(), "Explicit missing content result")
	registry = manager.load_content(["res://examples/railgun"], false)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.player.state = CharacterState.new(registry)
	check(game.player.state.grant_development_item("example_railgun:railgun"), "Dev inventory grants registered item")
	game.player.state.activate(3)
	game.die = func(): return 3
	var enemy = game.enemies[0]
	game.grid.occupants.erase(enemy.hex)
	enemy.hex = game.player.hex + Vector2i(7,0)
	game.grid.occupants[enemy.hex] = enemy
	enemy.health = 20
	var captured: Array = []
	game.hooks.emitted.connect(func(event, payload): captured.append({"event": event, "payload": payload}))
	check(game.fire_at(enemy.hex), "Data-only railgun fires at seven hexes")
	check(enemy.health == 8 and game.scheduler.world_time == 180, "Railgun damage and cost")
	check(captured[0].event == "on_attack" and captured[0].payload.result.effective_skill == 10, "Railgun accuracy and attack hook")
	check(captured[1].event == "on_hit" and captured[2].event == "on_damage_taken", "Hit precedes damage hooks")
	await create_timer(0.2).timeout
	game.player.state.activate(0)
	check(game.player.state.active_ranged_weapon().id == "base:pistol_weapon", "Pistol still available")
	game.free()
	registry = manager.load_content([], false)
	check(not registry.contains("example_railgun:railgun"), "Next load without mod removes content")
	check(registry.snapshot_metadata().schema_version == 1, "Save metadata contract")
	print("Mod checks: %d; failures: %d" % [checks, failures])
	quit(0 if failures == 0 else 1)
