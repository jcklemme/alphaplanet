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
	log_event("An Alien Stalker is approaching. X examines; Space waits.")

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
	if game_over or player.moving or HexMath.distance(player.hex, target) != 1:
		return false
	var occupant = grid.occupants.get(target)
	if occupant is AlienStalker and occupant.health > 0:
		occupant.health -= player.melee_damage
		log_event("You hit Stalker for %d." % player.melee_damage)
		if occupant.health <= 0:
			grid.occupants.erase(occupant.hex)
			scheduler.unregister(occupant)
			enemies.erase(occupant)
			occupant.queue_free()
			log_event("Stalker defeated.")
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
	board.hover = HexMath.from_world(get_global_mouse_position(), HexBoard.SIZE)
	if not game_over and not player.moving and not route.is_empty():
		var next: Vector2i = route.pop_front()
		if not attempt_step(next):
			route.clear()
	board.route = route
	board.queue_redraw()
	hud.update_status(player.hex, player.health, player.max_health, actions, scheduler.world_time, "\n".join(events))

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
		if not player.moving:
			log_event("You wait.")
			commit_action(TurnScheduler.WAIT_COST)
	elif event.is_action_pressed("examine"):
		log_event("Stalker: 7 max HP, 2 damage, 100 interval. Your melee damage: 5.")
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var target = HexMath.from_world(get_global_mouse_position(), HexBoard.SIZE)
		route.clear()
		if grid.occupants.get(target) is AlienStalker and HexMath.distance(player.hex, target) == 1:
			attempt_step(target)
		else:
			route = HexPathfinder.find_path(grid, player.hex, target)
