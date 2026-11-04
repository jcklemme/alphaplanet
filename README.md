# AlphaPlanet — Prototype 0.1a

A Godot 4 / GDScript single-player, top-down science-fiction movement prototype. Tested with Godot 4.6.3; no external assets, plugins, or dependencies.

## Launch

Import `project.godot` in the Godot 4 project manager, open the project, and press **F6** with `scenes/main.tscn` open or **F5** to run the project. From a terminal:

```sh
cd /path/to/alphaplanet
godot --editor --path .
# Or run directly:
godot --path .
```

`.godot/` contains generated editor data and is ignored by Git. Keep `.gd.uid` files alongside their scripts in version control.

## Controls

Click an open tile to follow its shortest reachable route. Hover highlights the selected tile; teal tiles show the remaining route, gray tiles are solid, and the cyan marker is the player. The camera follows the player. Escape cancels remaining steps (an already committed step finishes). Clicking during movement replaces the remaining route from the committed destination.

Keyboard: **D** east, **E** northeast, **W** northwest, **A** west, **Q** southwest, **S** southeast. Key presses during animation are ignored. There are no timers that spend actions while idle: each legal tile step consumes one action; blocked attempts consume none.

## Folder structure and contracts

| Path | Responsibility |
| --- | --- |
| `world/hex_math.gd` | Pointy-top axial `(q,r)` math, cube rounding, six neighbors, hex distance, world conversion |
| `world/hex_grid.gd` | Bounds, solid terrain, actor occupancy, atomic legal movement |
| `world/hex_pathfinder.gd` | Uniform-cost hex A*, with distance heuristic; no rendering dependencies |
| `world/game.gd` | Scene coordination, input, route execution, static map, action count |
| `entities/player.gd` | Player coordinate and visual animation; emits action cost on successful movement |
| `rendering/hex_board.gd` | Placeholder polygons, hover and route presentation; tile size lives here |
| `ui/hud.gd` | Controls and status overlay |
| `scenes/main.tscn` | Runnable scene entry point |
| `tests/` | Standalone logical regression tests and scene movement smoke test |

The map is a 30 × 20 axial parallelogram (600 tiles), with fixed obstacles and a gap. Coordinates are logical tile identities, never pixel positions. A* paths exclude the origin and include the goal; an empty path means no steps are required or no valid route exists. Occupied goals cannot be targeted for movement. Each step revalidates the route against current occupancy. Logical occupancy changes before its 0.12-second visual tween; no second movement starts until the animation completes. Click targeting uses the camera-aware world mouse position.

## Extension boundaries

`action_committed(origin, destination, cost)` exposes the unit action cost for a future turn scheduler. A scheduler should gate route steps and resolve other actors between actions; the current prototype only counts player actions. Future enemies can share `HexGrid` occupancy and pathfinding. Map generation can populate a new logical grid without changing rendering math.

Future projectiles can use Node2D world positions independently of tile identity. `HexMath.distance` supports future range checks. Line of sight should be a separate service (cube interpolation/rounding over the grid), with an explicit opacity policy separate from movement blocking. Character definitions, upgrades, and effects can later use Godot Resources without adding combat rules to grid math. LOS, projectiles, enemy AI, procedural generation, inventory, upgrades, and combat are intentionally not implemented.

## Automated validation

Run the editor import first on a fresh checkout to populate Godot's global script class cache:

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script tests/run_tests.gd
godot --headless --path . --script tests/smoke.gd
godot --headless --path . --quit-after 60
```

Tests exit nonzero on failure. The logic suite covers positive/negative coordinate round trips and interior rounding, pointy-top basis, unique/symmetric adjacency, hex distances, illegal and legal moves, atomic occupancy, reachable/blocked/occupied/disconnected paths, and shortest detours compared with an independent BFS. The smoke test instantiates the actual scene and checks three animated steps, action costs, occupancy, and final world position.

Validation on Godot 4.6.3: **933 logic checks, zero failures; scene movement smoke PASS; headless editor import and 60-frame startup passed.** Interactive mouse/keyboard and visual appearance have not been manually tested. The first restricted editor invocation reported unwritable home/cache paths and denied local sockets; rerunning with writable XDG directories and local socket permission passed. In a restricted cloud shell, use writable directories:

```sh
mkdir -p /tmp/alphaplanet-godot/{data,config,cache}
export XDG_DATA_HOME=/tmp/alphaplanet-godot/data
export XDG_CONFIG_HOME=/tmp/alphaplanet-godot/config
export XDG_CACHE_HOME=/tmp/alphaplanet-godot/cache
```
