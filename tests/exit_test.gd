extends SceneTree
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var menu = load("res://scenes/menu.tscn").instantiate()
	root.add_child(menu)
	print("Invoking menu Exit Game")
	menu.exit_game()
