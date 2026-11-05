class_name AlienStalker
extends Node2D
var anatomy = CharacterState.new().anatomy
var combat_skill := 10
var hex := Vector2i(21, 12)
var max_health := 7
var health := 7
var melee_damage := 2
var action_interval := 100

func _draw() -> void:
	draw_circle(Vector2.ZERO, 14, Color("e77781"))
	draw_line(Vector2(-9, -7), Vector2(9, 7), Color.WHITE, 2)
	draw_line(Vector2(-9, 7), Vector2(9, -7), Color.WHITE, 2)

var content_id := "base:stalker"
var display_name := "Alien Stalker"
func configure(content: ContentRegistry) -> void:
	var definition = content.get_definition(content_id, "enemies")
	assert(not definition.is_empty())
	display_name = definition.name
	max_health = int(definition.health)
	health = max_health
	melee_damage = int(definition.damage)
	action_interval = int(definition.interval)
	combat_skill = int(definition.combat_skill)
