class_name RunManager
extends RefCounted
static func start(tree: SceneTree) -> Error:
	return tree.change_scene_to_file("res://scenes/main.tscn")
static func end(tree: SceneTree) -> Error:
	tree.paused = false
	return tree.change_scene_to_file("res://scenes/menu.tscn")
