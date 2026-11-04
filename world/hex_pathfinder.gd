class_name HexPathfinder
extends RefCounted
## Uniform-cost A*. Returned path excludes origin and includes destination.
static func find_path(grid: HexGrid, origin: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var empty: Array[Vector2i] = []
	if not grid.contains(origin) or grid.blocked.has(origin) or not grid.contains(goal):
		return empty
	if origin == goal or not grid.is_open(goal):
		return empty
	var frontier: Array[Vector2i] = [origin]
	var costs: Dictionary = {origin: 0}
	var previous: Dictionary = {}
	while not frontier.is_empty():
		var best = 0
		for index in range(1, frontier.size()):
			if costs[frontier[index]] + HexMath.distance(frontier[index], goal) < costs[frontier[best]] + HexMath.distance(frontier[best], goal):
				best = index
		var current = frontier[best]
		frontier.remove_at(best)
		if current == goal:
			var path: Array[Vector2i] = []
			while current != origin:
				path.push_front(current)
				current = previous[current]
			return path
		for next in HexMath.neighbors(current):
			if not grid.is_open(next):
				continue
			var cost: int = costs[current] + 1
			if not costs.has(next) or cost < costs[next]:
				costs[next] = cost
				previous[next] = current
				if not frontier.has(next):
					frontier.append(next)
	return empty
