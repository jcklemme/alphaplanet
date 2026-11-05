extends Node2D
var mods := ModManager.new()
var content: ContentRegistry
var hooks := GameplayEvents.new()
var grid := HexGrid.new()
var board := HexBoard.new()
var player := HexPlayer.new()
var hud := PrototypeHUD.new()
var scheduler := TurnScheduler.new()
var enemies: Array[AlienStalker] = []
var route: Array[Vector2i] = []
var actions := 0
var events: Array[String] = []
var event_log := GameEventLog.new()
var die: Callable
var world := Node2D.new()
var game_over := false
var shot_busy := false
var pointer_position := Vector2.ZERO
var inspected_hex := Vector2i.ZERO
var has_inspection := false

func _ready() -> void:
	content = mods.load_content()
	if not content.contains("base:stalker") or not content.contains("base:pistol_weapon"):
		push_error("Required base content unavailable: " + str(content.diagnostics))
		set_process(false)
		return
	player.state = CharacterState.new(content)
	player.melee_damage = int(content.get_definition("base:knife_weapon").damage)
	# Explicit developer option: -- --dev-item=namespace:item, never auto-grant mod items.
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--dev-item="):
			if not player.state.grant_development_item(argument.trim_prefix("--dev-item=")):
				content.diagnostics.append("Requested development item is missing: " + argument)

	for r in range(3, 17):
		if r != 9:
			grid.blocked[Vector2i(12, r)] = true
	for q in range(17, 23):
		grid.blocked[Vector2i(q, 6)] = true
	hud.state = player.state
	hud.event_log = event_log
	add_child(hud)
	hud.map_view.add_child(world)
	hud.modal_opened.connect(func(): route.clear())
	board.grid = grid
	world.add_child(board)
	world.add_child(player)
	assert(grid.place(player, player.hex))
	player.position = HexMath.to_world(player.hex, HexBoard.SIZE)
	player.action_committed.connect(_on_action)
	player.add_child(Camera2D.new())
	var stalker = AlienStalker.new()
	stalker.configure(content)
	assert(not HexPathfinder.find_path(grid, player.hex, stalker.hex).is_empty())
	assert(grid.place(stalker, stalker.hex))
	enemies.append(stalker)
	world.add_child(stalker)
	stalker.position = HexMath.to_world(stalker.hex, HexBoard.SIZE)
	scheduler.register(stalker, stalker.action_interval)
	for diagnostic in content.diagnostics:
		log_event(diagnostic)
	log_event("An Alien Stalker is approaching. S examines; Space waits.")

func log_event(text: String, category := "System") -> void:
	event_log.append(text, category)

func attack_check(skill: int, description: String, attacker := "player", target := "stalker") -> bool:
	var result = SkillCheck.roll(skill, {}, die)
	hooks.publish("on_attack", {"attacker": attacker, "target": target, "result": result})
	if result.success:
		hooks.publish("on_hit", {"attacker": attacker, "target": target, "result": result})
	log_event("%s: %s = %d vs skill %d — %s by %d" % [description, str(result.dice), result.total, result.effective_skill, "Success" if result.success else "Failure", abs(result.margin)], "Combat")
	return result.success

func _on_action(_origin: Vector2i, _destination: Vector2i, cost: int) -> void:
	log_event("You move to (%d, %d)." % [_destination.x, _destination.y], "Movement")
	hooks.publish("on_move", {"actor": "player", "origin": _origin, "destination": _destination})
	commit_action(cost)

func commit_action(cost: int) -> void:
	hooks.publish("on_turn_start", {"actor": "player", "time": scheduler.world_time, "cost": cost})
	if cost > 0:
		actions += 1
	scheduler.advance(cost, enemy_turn, func(): return game_over)

func attempt_step(target: Vector2i) -> bool:
	if game_over or player.moving or shot_busy or HexMath.distance(player.hex, target) != 1:
		return false
	var occupant = grid.occupants.get(target)
	if occupant is AlienStalker and occupant.health > 0:
		if attack_check(player.state.skills.melee, "You attack Stalker in melee"):
			damage_enemy(occupant, player.melee_damage, "You hit Stalker")
		commit_action(int(content.get_definition("base:knife_weapon").action_cost))
		return true
	if not grid.can_move(player, player.hex, target):
		log_event("Movement blocked.")
		return false
	player.step(grid, target, HexBoard.SIZE)
	return true

func enemy_turn(enemy: AlienStalker) -> void:
	if enemy.health <= 0 or game_over:
		return
	hooks.publish("on_turn_start", {"actor": "stalker", "time": scheduler.world_time})
	if HexMath.distance(enemy.hex, player.hex) == 1:
		if not attack_check(enemy.combat_skill, "Stalker attacks", "stalker", "player"):
			return
		player.health = maxi(0, player.health - enemy.melee_damage)
		hooks.publish("on_damage_taken", {"actor": "player", "damage": enemy.melee_damage, "health": player.health})
		log_event("Stalker hits you for %d." % enemy.melee_damage)
		if player.health == 0:
			hooks.publish("on_kill", {"actor": "player", "killer": "stalker"})
			game_over = true
			route.clear()
			log_event("GAME OVER — Press R to restart.")
		return
	# Seek an open attack position without treating the player's occupied tile as open.
	var best: Array[Vector2i] = []
	for goal in HexMath.neighbors(player.hex):
		var path = HexPathfinder.find_path(grid, enemy.hex, goal)
		if not path.is_empty() and (best.is_empty() or path.size() < best.size()):
			best = path
	var previous_hex = enemy.hex
	if not best.is_empty() and grid.move(enemy, enemy.hex, best[0]):
		enemy.hex = best[0]
		enemy.position = HexMath.to_world(enemy.hex, HexBoard.SIZE)
		hooks.publish("on_move", {"actor": "stalker", "origin": previous_hex, "destination": enemy.hex})

func _process(_delta: float) -> void:
	board.hover = hovered_hex()
	if not hud.modal_active and not game_over and not player.moving and not shot_busy and not route.is_empty():
		var next: Vector2i = route.pop_front()
		if not attempt_step(next):
			route.clear()
	board.route = route
	board.queue_redraw()
	hud.update_status(player.hex, player.health, player.max_health, actions, scheduler.world_time, "\n".join(events))
	if has_inspection:
		hud.show_inspection(HexInspection.describe(grid, inspected_hex))

func _unhandled_input(event: InputEvent) -> void:
	if hud.modal_active:
		return
	if event is InputEventKey and event.echo:
		return
	if game_over:
		if event.is_action_pressed("restart"):
			get_tree().reload_current_scene()
		return
	for action in HexControls.MOVES:
		if event.is_action_pressed(action):
			route.clear() # Also cancel during an already committed animated step.
			attempt_step(player.hex + HexControls.MOVES[action])
			return
	if event.is_action_pressed("cancel_route"):
		route.clear()
	elif event.is_action_pressed("wait_turn"):
		route.clear()
		if not player.moving and not shot_busy:
			log_event("You wait.")
			commit_action(TurnScheduler.WAIT_COST)
	elif event.is_action_pressed("examine"):
		examine_hover()
	elif event.is_action_pressed("fire"):
		if not hud.pointer_over_ui(pointer_position):
			fire_at(hovered_hex())
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if hud.pointer_over_ui(pointer_position):
			return
		var target = hovered_hex()
		route.clear()
		if grid.occupants.get(target) is AlienStalker and HexMath.distance(player.hex, target) == 1:
			attempt_step(target)
		else:
			route = HexPathfinder.find_path(grid, player.hex, target)

func hovered_hex() -> Vector2i:
	return HexMath.from_world(board.get_global_transform_with_canvas().affine_inverse() * pointer_position, HexBoard.SIZE)

func examine_hover() -> void:
	# Stop automatic route execution so examination never indirectly spends a turn.
	route.clear()
	if hud.pointer_over_ui(pointer_position):
		return
	inspected_hex = hovered_hex()
	has_inspection = true
	hud.show_inspection(HexInspection.describe(grid, inspected_hex))
	log_event(HexInspection.describe(grid, inspected_hex), "Examination")

func damage_enemy(enemy: AlienStalker, damage: int, description: String) -> void:
	if enemy.health <= 0:
		return
	enemy.health = maxi(0, enemy.health - damage)
	hooks.publish("on_damage_taken", {"actor": "stalker", "damage": damage, "health": enemy.health})
	log_event("%s for %d." % [description, damage], "Damage")
	if enemy.health == 0:
		grid.remains[enemy.hex] = "Alien Stalker"
		grid.occupants.erase(enemy.hex)
		scheduler.unregister(enemy)
		enemies.erase(enemy)
		hooks.publish("on_kill", {"actor": "stalker", "killer": "player", "content_id": enemy.content_id})
		enemy.queue_free()
		log_event("Stalker defeated.")
	if has_inspection:
		hud.show_inspection(HexInspection.describe(grid, inspected_hex))

func fire_at(target: Vector2i) -> bool:
	route.clear()
	if game_over or player.moving or shot_busy:
		return false
	var weapon = player.state.active_ranged_weapon()
	if weapon.is_empty():
		log_event("Equip the Plasma Pistol group to fire.", "Items")
		return false
	var reason = RangedTargeting.rejection(grid, player.hex, target, int(weapon.range))
	if not reason.is_empty():
		log_event(reason)
		return false
	shot_busy = true
	var beam = ShotBeam.new()
	beam.position = player.position
	beam.destination = HexMath.to_world(target, HexBoard.SIZE) - beam.position
	world.add_child(beam)
	if attack_check(int(weapon.get("skill_override", player.state.skills.ranged)), "You fire the " + weapon.name):
		damage_enemy(grid.occupants[target], int(weapon.damage), weapon.name + " hits Stalker")
	commit_action(int(weapon.action_cost))
	get_tree().create_timer(0.18).timeout.connect(func(): shot_busy = false)
	return true

func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		pointer_position = event.position
