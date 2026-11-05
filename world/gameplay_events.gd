class_name GameplayEvents
extends RefCounted
signal emitted(event_name: String, payload: Dictionary)
const NAMES = ["on_attack", "on_hit", "on_damage_taken", "on_kill", "on_move", "on_turn_start", "on_item_used"]
func publish(event_name: String, payload: Dictionary) -> void:
	assert(NAMES.has(event_name))
	emitted.emit(event_name, payload.duplicate(true))
