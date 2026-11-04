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
func key(game: Node, code: int, echo := false) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	event.echo = echo
	game._unhandled_input(event)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var origin: Vector2i = game.player.hex
	var enemy = game.enemies[0]
	var spawn: Vector2i = enemy.hex
	await create_timer(0.2).timeout
	check(game.scheduler.world_time == 0 and enemy.hex == spawn, "Idle time freezes world")
	var codes = [KEY_Q, KEY_E, KEY_A, KEY_D, KEY_Z, KEY_S]
	var directions = [Vector2i(0,-1), Vector2i(1,-1), Vector2i(-1,0), Vector2i(1,0), Vector2i(-1,1), Vector2i(0,1)]
	for i in 6:
		var before: Vector2i = game.player.hex
		var time: int = game.scheduler.world_time
		key(game, codes[i])
		check(game.player.hex == before + directions[i], "Physical key maps to correct neighbor")
		check(game.scheduler.world_time == time + 100, "One move consumes 100")
		key(game, codes[i], true)
		check(game.scheduler.world_time == time + 100, "Key repeat spends no turn")
		await create_timer(0.15).timeout
	check(enemy.hex != spawn, "Scheduled enemy moves")
	game.grid.blocked[game.player.hex + Vector2i(1,0)] = true
	var time: int = game.scheduler.world_time
	game.route.assign([game.player.hex + Vector2i(0,1)])
	key(game, KEY_D)
	check(game.route.is_empty(), "Keyboard cancels route even when blocked")
	check(game.scheduler.world_time == time, "Wall costs no time")
	game.grid.blocked.erase(game.player.hex + Vector2i(1,0))
	key(game, KEY_D)
	game.route.assign([game.player.hex + Vector2i(1,0)])
	key(game, KEY_Q)
	check(game.route.is_empty(), "Keyboard cancels route during animation")
	check(game.scheduler.world_time == time + 100, "Busy input cannot double turn")
	await create_timer(0.15).timeout
	time = game.scheduler.world_time
	key(game, KEY_X)
	check(game.scheduler.world_time == time, "Examine is free")
	key(game, KEY_SPACE)
	check(game.scheduler.world_time == time + 100, "Wait costs 100")
	game.grid.occupants.erase(enemy.hex)
	enemy.hex = game.player.hex + Vector2i(1,0)
	game.grid.occupants[enemy.hex] = enemy
	origin = game.player.hex
	key(game, KEY_D)
	check(enemy.health == 2 and game.player.hex == origin, "Melee deals five without moving")
	check(game.player.health == 18, "Adjacent scheduled enemy deals two")
	var dead_hex: Vector2i = enemy.hex
	key(game, KEY_D)
	check(game.enemies.is_empty() and not game.grid.occupants.has(dead_hex) and game.scheduler.due.is_empty(), "Death removes occupancy and scheduling")
	key(game, KEY_SPACE)
	check(game.player.health == 18, "Dead enemy cannot act")
	game.free()
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	enemy = game.enemies[0]
	game.grid.occupants.erase(enemy.hex)
	enemy.hex = game.player.hex + Vector2i(1,0)
	game.grid.occupants[enemy.hex] = enemy
	game.player.health = 2
	key(game, KEY_SPACE)
	check(game.game_over and game.player.health == 0, "Lethal enemy attack ends game")
	time = game.scheduler.world_time
	key(game, KEY_SPACE)
	key(game, KEY_D)
	check(game.scheduler.world_time == time, "Game over blocks actions")
	current_scene = game
	key(game, KEY_R)
	await process_frame
	await process_frame
	check(current_scene != null and current_scene.player.health == 20 and current_scene.scheduler.world_time == 0 and current_scene.enemies.size() == 1, "Restart creates fresh game")
	current_scene.free()
	var scheduler = TurnScheduler.new()
	var fast = RefCounted.new()
	var slow = RefCounted.new()
	var counts = {fast: 0, slow: 0}
	scheduler.register(fast, 50)
	scheduler.register(slow, 150)
	scheduler.advance(300, func(actor): counts[actor] += 1, func(): return false)
	check(counts[fast] == 6 and counts[slow] == 2 and scheduler.world_time == 300, "Different speeds and larger costs")
	print("Combat checks: %d; failures: %d" % [checks, failures])
	quit(0 if failures == 0 else 1)
