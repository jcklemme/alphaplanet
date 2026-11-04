extends SceneTree

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var origin: Vector2i = game.player.hex
	game.route = HexPathfinder.find_path(game.grid, origin, origin + Vector2i(3, 0))
	await create_timer(0.8).timeout
	var passed: bool = game.player.hex == origin + Vector2i(3, 0) and game.actions == 3 and not game.player.moving and game.grid.occupants.get(game.player.hex) == game.player and game.player.position.is_equal_approx(HexMath.to_world(game.player.hex, HexBoard.SIZE))
	print("Scene movement smoke: ", "PASS" if passed else "FAIL")
	game.free()
	quit(0 if passed else 1)
