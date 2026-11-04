extends Node2D
var grid := HexGrid.new()
var board := HexBoard.new()
var player := HexPlayer.new()
var hud := PrototypeHUD.new()
var route: Array[Vector2i] = []
var actions := 0
var message := "Select a destination. Gray tiles are solid."

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
	var camera = Camera2D.new()
	player.add_child(camera)
	add_child(hud)

func _on_action(_origin: Vector2i, _destination: Vector2i, cost: int) -> void:
	actions += cost

func _process(_delta: float) -> void:
	board.hover = HexMath.from_world(get_global_mouse_position(), HexBoard.SIZE)
	if not player.moving and not route.is_empty():
		var next: Vector2i = route.pop_front()
		if grid.can_move(player, player.hex, next):
			player.step(grid, next, HexBoard.SIZE)
		else:
			route.clear()
			message = "Route obstructed. Select another destination."
	board.route = route
	board.queue_redraw()
	hud.update_status(player.hex, actions, message)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var target = HexMath.from_world(get_global_mouse_position(), HexBoard.SIZE)
		route = HexPathfinder.find_path(grid, player.hex, target)
		message = "Route selected." if not route.is_empty() else "Already there or destination unreachable."
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			route.clear()
			message = "Route cancelled."
		var keys = [KEY_D, KEY_E, KEY_W, KEY_A, KEY_Q, KEY_S]
		var index = keys.find(event.keycode)
		if index >= 0 and not player.moving:
			route.clear()
			var target = player.hex + HexMath.DIRECTIONS[index]
			if grid.can_move(player, player.hex, target):
				route.append(target)
				message = "Single step."
			else:
				message = "Movement blocked."
