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
	for i in 500:
		var result = SkillCheck.roll(12)
		check(result.total >= 3 and result.total <= 18 and result.dice.size() == 3, "3d6 range")
	var result = SkillCheck.roll(12, {"range": -3}, func(): return 3)
	check(result.success and result.margin == 0 and result.effective_skill == 9 and result.modifiers.range == -3, "Modifiers and equality")
	check(SkillCheck.roll(1, {}, func(): return 1).effective_skill == 1, "No low clamp")
	check(SkillCheck.roll(22, {}, func(): return 6).margin == 4, "No high clamp")
	var state = CharacterState.new()
	state.toggle_pin("stim")
	check(state.ordered_items()[0] == "stim", "Pinned first")
	state.toggle_pin("stim")
	check(state.ordered_items()[0] == "pistol", "Unpin restores ordering")
	state.activate(1)
	check(state.equipped() == ["knife"], "Group changes equipment")
	state.activate(2)
	check(state.equipped().is_empty(), "Unarmed group")
	state.anatomy.append({"id": "tail"})
	check(state.anatomy.size() == 7 and CharacterState.new().anatomy.size() == 6, "Independent extensible anatomy")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var enemy = game.enemies[0]
	game.grid.occupants.erase(enemy.hex)
	enemy.hex = game.player.hex + Vector2i(1, 0)
	game.grid.occupants[enemy.hex] = enemy
	game.die = func(): return 6
	game.attempt_step(enemy.hex)
	check(enemy.health == 7 and game.player.health == 20 and game.scheduler.world_time == 100, "Failed player and enemy attacks deal no damage but consume turn")
	game.die = func(): return 2
	game.attempt_step(enemy.hex)
	check(enemy.health == 2 and game.player.health == 18, "Successful attacks apply damage once")
	game.attempt_step(enemy.hex)
	check(game.enemies.is_empty() and game.scheduler.due.is_empty() and game.player.health == 18, "Dead enemy cannot retaliate")
	var event = InputEventKey.new()
	event.physical_keycode = KEY_D
	event.pressed = true
	var before: Vector2i = game.player.hex
	game.hud.open_inventory()
	game._unhandled_input(event)
	check(game.player.hex == before and game.hud.modal_active, "Modal blocks keyboard")
	game.hud.close_inventory()
	game._unhandled_input(event)
	check(game.player.hex == before + Vector2i(1,0), "Closing modal restores gameplay")
	await create_timer(0.15).timeout
	for size in [Vector2i(1280,800), Vector2i(1000,700), Vector2i(1600,900)]:
		root.content_scale_size = size
		game.hud.layout()
		await process_frame
		var target: Vector2i = game.player.hex + Vector2i(1,1)
		game.pointer_position = game.board.get_global_transform_with_canvas() * HexMath.to_world(target, HexBoard.SIZE)
		check(game.hovered_hex() == target and not game.hud.pointer_over_ui(game.pointer_position), "Resized map targeting")
		check(game.hud.bottom.position.y == game.hud.map_size.y and game.hud.sidebar.position.x == game.hud.map_size.x, "Non-overlapping layout")
	for i in 350:
		game.event_log.append(str(i), "System")
	check(game.event_log.entries.size() == 300 and game.event_log.entries.back().text == "349", "Bounded chronological log")
	game.free()
	print("Prototype 3 checks: %d; failures: %d" % [checks, failures])
	quit(0 if failures == 0 else 1)
