extends SceneTree
var failures := 0
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _init() -> void:
	call_deferred("run")
func relocate(game: Node, enemy: AlienStalker, hex: Vector2i) -> void:
	game.grid.occupants.erase(enemy.hex)
	enemy.hex = hex
	game.grid.occupants[hex] = enemy
	enemy.position = HexMath.to_world(hex, HexBoard.SIZE)
func key(game: Node, code: int) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	game._unhandled_input(event)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var enemy = game.enemies[0]
	var origin: Vector2i = game.player.hex
	check(HexInspection.describe(game.grid, origin).contains("20/20"), "Player inspection")
	check(HexInspection.describe(game.grid, Vector2i(12,3)).contains("Impassable"), "Wall inspection")
	check(HexInspection.describe(game.grid, Vector2i(-1,0)).contains("Outside"), "Off-map inspection")
	# Camera-aware mouse position away from the HUD.
	var mouse_world = HexMath.to_world(origin + Vector2i(1,1), HexBoard.SIZE)
	var motion = InputEventMouseMotion.new()
	motion.position = game.get_global_transform_with_canvas() * mouse_world
	root.push_input(motion, true)
	game._input(motion)
	await process_frame
	var hovered: Vector2i = game.hovered_hex()
	check(hovered == origin + Vector2i(1,1), "Mouse transforms to correct axial tile")
	key(game, KEY_S)
	check(game.player.hex == origin and game.scheduler.world_time == 0, "S examines without move/time")
	check(game.hud.inspection.text == HexInspection.describe(game.grid, hovered), "Mouse inspection uses actual hovered contents")
	var target = origin + Vector2i(2,1)
	relocate(game, enemy, target)
	check(HexInspection.describe(game.grid, target).contains("7/7"), "Living enemy current HP")
	game.inspected_hex = target
	game.has_inspection = true
	check(game.fire_at(target), "Non-axis shot succeeds")
	check(enemy.health == 4 and game.scheduler.world_time == 120 and game.actions == 1, "Shot deals exactly three and costs 120")
	check(not game.fire_at(enemy.hex) and game.scheduler.world_time == 120, "Shot animation blocks duplicate action")
	check(enemy.hex != target, "Shot schedules enemy movement")
	await create_timer(0.2).timeout
	check(game.scheduler.world_time == 120, "Animation does not advance simulation")
	relocate(game, enemy, target)
	var line = HexSight.line(origin, target)
	var reverse = HexSight.line(target, origin)
	reverse.reverse()
	check(line == reverse, "LOS is symmetric at rounding ties")
	game.grid.blocked[line[1]] = true
	check(not game.fire_at(target), "Wall blocks shot")
	game.grid.blocked.erase(line[1])
	relocate(game, enemy, origin + Vector2i(6,0))
	check(not game.fire_at(enemy.hex), "Range rejection")
	check(not game.fire_at(Vector2i(-1,-1)), "Off-map shot rejection")
	check(not game.fire_at(origin + Vector2i(0,1)), "Empty shot rejection")
	check(game.scheduler.world_time == 120 and game.actions == 1, "Invalid shots spend no time/actions")
	relocate(game, enemy, target)
	enemy.health = 3
	game.inspected_hex = target
	check(game.fire_at(target), "Lethal shot succeeds")
	check(game.enemies.is_empty() and not game.grid.occupants.has(target) and game.scheduler.due.is_empty(), "Ranged kill removes living entity/occupancy/schedule")
	check(game.hud.inspection.text.contains("Floor") and not game.hud.inspection.text.contains("Stalker"), "Dead inspection refreshed immediately")
	await create_timer(0.2).timeout
	check(not game.fire_at(target) and game.scheduler.world_time == 240, "Former enemy tile is not a target")
	# Mouse click route and hover are still camera-aware.
	mouse_world = HexMath.to_world(origin + Vector2i(1,1), HexBoard.SIZE)
	motion.position = game.get_global_transform_with_canvas() * mouse_world
	root.push_input(motion, true)
	game._input(motion)
	await process_frame
	var click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	game._unhandled_input(click)
	check(not game.route.is_empty(), "Mouse selects path")
	await create_timer(0.5).timeout
	check(game.player.hex == origin + Vector2i(1,1), "Mouse route reaches target")
	game.free()
	print("Ranged/inspection checks: %d; failures: %d" % [checks, failures])
	quit(0 if failures == 0 else 1)
