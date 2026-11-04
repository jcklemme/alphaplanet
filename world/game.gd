extends Node2D
var grid := HexGrid.new()
var board := HexBoard.new()
var player := HexPlayer.new()
var hud := PrototypeHUD.new()
var scheduler := TurnScheduler.new()
var enemies: Array[AlienStalker] = []
var route: Array[Vector2i] = []
var actions := 0
var events: Array[String] = []
var game_over := false
var shot_busy := false
var pointer_position := Vector2.ZERO
var inspected_hex := Vector2i.ZERO
var has_inspection := false

func _ready() -> void:
	for r in range(3, 17):
		if r != 9:
			grid.blocked[Vector2i(12, r)] = true
	for q in range(17, 23):
		grid.blocked[Vector2i(q, 6)] = true
	board.grid = grid
	add_child(board)
	add_child(player)
	assert(grid.place(player, player.hex))
	player.position = HexMath.to_world(player.hex, HexBoard.SIZE)
	player.action_committed.connect(_on_action)
	player.add_child(Camera2D.new())
	var stalker = AlienStalker.new()
	assert(not HexPathfinder.find_path(grid, player.hex, stalker.hex).is_empty())
	assert(grid.place(stalker, stalker.hex))
	enemies.append(stalker)
	add_child(stalker)
	stalker.position = HexMath.to_world(stalker.hex, HexBoard.SIZE)
	scheduler.register(stalker, stalker.action_interval)
	add_child(hud)
	log_event("An Alien Stalker is approaching. S examines; Space waits.")

func log_event(text: String) -> void:
	events.append(text)
	if events.size() > 5:
		events.pop_front()

func _on_action(_origin: Vector2i, _destination: Vector2i, cost: int) -> void:
	commit_action(cost)

func commit_action(cost: int) -> void:
	if cost > 0:
		actions += 1
	scheduler.advance(cost, enemy_turn, func(): return game_over)

func attempt_step(target: Vector2i) -> bool:
	if game_over or player.moving or shot_busy or HexMath.distance(player.hex, target) != 1:
		return false
	var occupant = grid.occupants.get(target)
	if occupant is AlienStalker and occupant.health > 0:
		damage_enemy(occupant, player.melee_damage, "You hit Stalker")
		commit_action(TurnScheduler.MELEE_COST)
		return true
	if not grid.can_move(player, player.hex, target):
		log_event("Movement blocked.")
		return false
	player.step(grid, target, HexBoard.SIZE)
	return true

func enemy_turn(enemy: AlienStalker) -> void:
	if enemy.health <= 0 or game_over:
		return
	if HexMath.distance(enemy.hex, player.hex) == 1:
		player.health = maxi(0, player.health - enemy.melee_damage)
		log_event("Stalker hits you for %d." % enemy.melee_damage)
		if player.health == 0:
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
	if not best.is_empty() and grid.move(enemy, enemy.hex, best[0]):
		enemy.hex = best[0]
		enemy.position = HexMath.to_world(enemy.hex, HexBoard.SIZE)

func _process(_delta: float) -> void:
	board.hover = hovered_hex()
	if not game_over and not player.moving and not shot_busy and not route.is_empty():
		var next: Vector2i = route.pop_front()
		if not attempt_step(next):
			route.clear()
	board.route = route
	board.queue_redraw()
	hud.update_status(player.hex, player.health, player.max_health, actions, scheduler.world_time, "\n".join(events))
	if has_inspection:
		hud.show_inspection(HexInspection.describe(grid, inspected_hex))

func _unhandled_input(event: InputEvent) -> void:
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
	return HexMath.from_world(get_global_transform_with_canvas().affine_inverse() * pointer_position, HexBoard.SIZE)

func examine_hover() -> void:
	# Stop automatic route execution so examination never indirectly spends a turn.
	route.clear()
	if hud.pointer_over_ui(pointer_position):
		return
	inspected_hex = hovered_hex()
	has_inspection = true
	hud.show_inspection(HexInspection.describe(grid, inspected_hex))

func damage_enemy(enemy: AlienStalker, damage: int, description: String) -> void:
	enemy.health = maxi(0, enemy.health - damage)
	log_event("%s for %d." % [description, damage])
	if enemy.health == 0:
		grid.occupants.erase(enemy.hex)
		scheduler.unregister(enemy)
		enemies.erase(enemy)
		enemy.queue_free()
		log_event("Stalker defeated.")
	if has_inspection:
		hud.show_inspection(HexInspection.describe(grid, inspected_hex))

func fire_at(target: Vector2i) -> bool:
	route.clear()
	if game_over or player.moving or shot_busy:
		return false
	var reason = RangedTargeting.rejection(grid, player.hex, target)
	if not reason.is_empty():
		log_event(reason)
		return false
	shot_busy = true
	var beam = ShotBeam.new()
	beam.position = player.position
	beam.destination = HexMath.to_world(target, HexBoard.SIZE) - beam.position
	add_child(beam)
	damage_enemy(grid.occupants[target], RangedTargeting.DAMAGE, "Energy pistol hits Stalker")
	commit_action(RangedTargeting.COST)
	get_tree().create_timer(0.18).timeout.connect(func(): shot_busy = false)
	return true

func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		pointer_position = event.position
