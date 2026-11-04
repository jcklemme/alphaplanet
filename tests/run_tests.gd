extends SceneTree
var checks := 0
var failures := 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func _init() -> void:
	for q in range(-10, 11):
		for r in range(-10, 11):
			var hex = Vector2i(q, r)
			check(HexMath.from_world(HexMath.to_world(hex, 28), 28) == hex, "Coordinate round trip")
			check(HexMath.from_world(HexMath.to_world(hex, 28) + Vector2(3, -2), 28) == hex, "Interior point rounds to tile")
	check(HexMath.to_world(Vector2i(0, 1), 28).is_equal_approx(Vector2(sqrt(3.0) * 14, 42)), "Pointy-top basis")
	var adjacent = HexMath.neighbors(Vector2i.ZERO)
	check(adjacent.size() == 6, "Six neighbors")
	var unique = {}
	for neighbor in adjacent:
		unique[neighbor] = true
		check(HexMath.distance(Vector2i.ZERO, neighbor) == 1, "Neighbor distance")
		check(HexMath.neighbors(neighbor).has(Vector2i.ZERO), "Symmetric adjacency")
	check(unique.size() == 6, "Distinct neighbors")
	check(HexMath.distance(Vector2i.ZERO, Vector2i(3, -2)) == 3, "Mixed-sign distance")
	check(HexMath.distance(Vector2i.ZERO, Vector2i(3, 2)) == 5, "Same-sign distance")
	check(HexMath.distance(Vector2i(4, -7), Vector2i(4, -7)) == 0, "Self distance")
	var grid = HexGrid.new(7, 7)
	var actor = RefCounted.new()
	var other = RefCounted.new()
	check(grid.place(actor, Vector2i(0, 0)), "Place actor")
	check(not grid.place(actor, Vector2i(2, 2)), "Reject duplicate placement")
	check(not grid.move(actor, Vector2i.ZERO, Vector2i(-1, 0)), "Reject outside map")
	check(not grid.move(actor, Vector2i.ZERO, Vector2i(2, 0)), "Reject nonadjacent move")
	grid.blocked[Vector2i(1, 0)] = true
	check(not grid.move(actor, Vector2i.ZERO, Vector2i(1, 0)), "Reject wall")
	check(grid.place(other, Vector2i(0, 1)), "Place second actor")
	check(not grid.move(actor, Vector2i.ZERO, Vector2i(0, 1)), "Reject occupied destination")
	check(grid.occupants.get(Vector2i.ZERO) == actor, "Failed move preserves origin")
	grid.blocked.clear()
	check(not grid.move(other, Vector2i.ZERO, Vector2i(1, 0)), "Reject wrong actor")
	check(grid.move(actor, Vector2i.ZERO, Vector2i(1, 0)), "Legal move succeeds")
	check(grid.is_open(Vector2i.ZERO) and grid.occupants.get(Vector2i(1, 0)) == actor, "Occupancy transfers")
	var path = HexPathfinder.find_path(grid, Vector2i(1, 0), Vector2i(6, 6))
	check(path.size() == 11, "Open map shortest path")
	for r in range(6):
		grid.blocked[Vector2i(3, r)] = true
	path = HexPathfinder.find_path(grid, Vector2i(1, 0), Vector2i(6, 0))
	check(path.size() == bfs_distance(grid, Vector2i(1, 0), Vector2i(6, 0)), "Detour is optimal against BFS")
	check(not path.is_empty() and path.back() == Vector2i(6, 0), "Path reaches goal")
	var current = Vector2i(1, 0)
	for next in path:
		check(grid.is_open(next) and HexMath.distance(current, next) == 1, "Every path edge legal")
		current = next
	grid.blocked[Vector2i(3, 6)] = true
	check(HexPathfinder.find_path(grid, Vector2i(1, 0), Vector2i(6, 0)).is_empty(), "Disconnected goal")
	check(HexPathfinder.find_path(grid, Vector2i(1, 0), Vector2i(0, 1)).is_empty(), "Occupied goal")
	check(HexPathfinder.find_path(grid, Vector2i(1, 0), Vector2i(3, 0)).is_empty(), "Blocked goal")
	check(HexPathfinder.find_path(grid, Vector2i(1, 0), Vector2i(1, 0)).is_empty(), "Same tile needs no steps")
	check(HexPathfinder.find_path(grid, Vector2i(-1, 0), Vector2i(2, 0)).is_empty(), "Invalid origin")
	print("Checks: %d; failures: %d" % [checks, failures])
	quit(0 if failures == 0 else 1)

func bfs_distance(grid: HexGrid, origin: Vector2i, goal: Vector2i) -> int:
	var queue: Array[Vector2i] = [origin]
	var distances = {origin: 0}
	while not queue.is_empty():
		var current = queue.pop_front()
		if current == goal:
			return distances[current]
		for next in HexMath.neighbors(current):
			if grid.is_open(next) and not distances.has(next):
				distances[next] = distances[current] + 1
				queue.append(next)
	return -1
