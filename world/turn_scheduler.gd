class_name TurnScheduler
extends RefCounted
## Discrete simulation clock. Never driven by frame time.
const MOVE_COST := 100
const MELEE_COST := 100
const WAIT_COST := 100
const EXAMINE_COST := 0
var world_time := 0
var due: Dictionary = {}
var intervals: Dictionary = {}

func register(actor: Object, interval: int) -> void:
	assert(interval > 0)
	intervals[actor] = interval
	due[actor] = world_time + interval

func unregister(actor: Object) -> void:
	due.erase(actor)
	intervals.erase(actor)

func advance(cost: int, act: Callable, stopped: Callable) -> void:
	assert(cost >= 0)
	var target = world_time + cost
	while cost > 0 and not stopped.call():
		var next: Object = null
		var time = target + 1
		for actor in due:
			if due[actor] < time:
				next = actor
				time = due[actor]
		if next == null:
			break
		world_time = time
		due[next] += intervals[next]
		act.call(next)
	world_time = target
