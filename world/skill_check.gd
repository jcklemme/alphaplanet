class_name SkillCheck
extends RefCounted
static func roll(base: int, modifiers: Dictionary = {}, die: Callable = Callable()) -> Dictionary:
	var dice: Array[int] = []
	var total := 0
	for i in 3:
		var value: int = die.call() if die.is_valid() else randi_range(1, 6)
		assert(value >= 1 and value <= 6)
		dice.append(value)
		total += value
	var effective = base
	for value in modifiers.values():
		effective += int(value)
	return {"dice": dice, "total": total, "base_skill": base, "modifiers": modifiers.duplicate(), "effective_skill": effective, "success": total <= effective, "margin": effective-total}
