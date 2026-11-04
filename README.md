# AlphaPlanet — Prototype 0.1c

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

Keyboard: **D** east, **E** northeast, **Q** northwest, **A** west, **Z** southwest, **X** southeast. Movement presses during animation cancel the remaining route without starting a second action. Space waits, S examines the mouse-hovered tile, F fires the energy pistol, and R restarts after Game Over. There are no timers that spend actions while idle: each legal tile step, melee attack, or wait consumes one action and 100 world-time units; blocked attempts and examining consume none.

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

`world/turn_scheduler.gd` owns a discrete world clock and per-actor due times and intervals. It processes due actors chronologically after each committed action; idle frames never advance it. Move, melee, and wait cost 100; examine costs zero. Costs and enemy intervals can differ without depending on animation speed. `world/hex_controls.gd` maps InputMap action names to axial offsets; bindings live in `project.godot`.

The player has 20 HP and deals 5 damage. `entities/stalker.gd` defines the Alien Stalker (7 HP, 2 damage, 100-unit interval). One spawns at reachable tile (21,12). It uses A* to approach an open tile adjacent to the player, respecting terrain and occupancy. Bumping an adjacent enemy, or clicking it, attacks without moving. Dead enemies leave occupancy and scheduling immediately. At zero player HP, actions stop and R reloads the scene. The HUD shows HP, actions, world time, and a five-message combat log.

`world/game.gd` coordinates deterministic combat and delegates time ordering to the scheduler. Movement still commits logically before its visual tween; enemy actions resolve immediately against the committed position. There is no real-time enemy timer. Future projectiles can use world positions independently; hex distance remains available for range and future LOS. Inventory, upgrades, procedural generation, inventory and upgrades remain outside this milestone.

## Automated validation

Run the editor import first on a fresh checkout to populate Godot's global script class cache:

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script tests/run_tests.gd
godot --headless --path . --script tests/smoke.gd
godot --headless --path . --script tests/combat_tests.gd
godot --headless --path . --script tests/ranged_tests.gd
godot --headless --path . --quit-after 60
```

Tests exit nonzero on failure. The logic suite covers positive/negative coordinate round trips and interior rounding, pointy-top basis, unique/symmetric adjacency, hex distances, illegal and legal moves, atomic occupancy, reachable/blocked/occupied/disconnected paths, and shortest detours compared with an independent BFS. Combat tests exercise physical InputMap keys, wall rejection, route cancellation including during animation, echo suppression, idle/examine/wait timing, enemy pursuit and damage, melee, death cleanup, Game Over, restart, and differing actor intervals. The smoke test instantiates the actual scene and checks three animated steps, action costs, occupancy, and final world position.

Validation on Godot 4.6.3: **933 grid checks, 34 control/combat checks, and 24 ranged/inspection checks, zero failures; scene movement smoke PASS; headless editor import and 60-frame startup passed.** Interactive mouse/keyboard and visual appearance have not been manually tested. The first restricted editor invocation reported unwritable home/cache paths and denied local sockets; rerunning with writable XDG directories and local socket permission passed. In a restricted cloud shell, use writable directories:

```sh
mkdir -p /tmp/alphaplanet-godot/{data,config,cache}
export XDG_DATA_HOME=/tmp/alphaplanet-godot/data
export XDG_CONFIG_HOME=/tmp/alphaplanet-godot/config
export XDG_CACHE_HOME=/tmp/alphaplanet-godot/cache
```

## Milestone 0.1c

The Basic Energy Pistol deals 3 damage at range 5 for 120 time units. F targets the living enemy at the mouse position, with no facing requirement. Invalid targets spend no actions or time. Shots cancel routes and suppress further actions during a brief visual-only beam; the turn scheduler resolves damage and due enemies immediately. Melee and ranged attacks share `damage_enemy` and death cleanup.

S examines current terrain or occupants at the mouse position, cancels automatic navigation, and spends no time. The inspection panel follows the selected tile's live contents. The stale Stalker report in 0.1b was a hardcoded Examine message, not failed occupancy cleanup. Mouse positions are captured from viewport events and transformed through the camera to world coordinates. UI-covered positions are ignored.

New modules:
- `world/hex_inspection.gd`: live occupancy and terrain descriptions.
- `world/hex_sight.gd`: deterministic cube-interpolated LOS with canonical endpoint order and fixed tie-breaking nudge. At exact boundary ties, one consistent side is selected; reversing the ray selects the same cells. Walls in those cells block shots; entities do not block shots.
- `world/ranged_targeting.gd`: living-target, range, and LOS validation, plus pistol constants.
- `rendering/shot_beam.gd`: short fading world-space beam; no combat or time advancement.
- `tests/ranged_tests.gd`: targeting, LOS, inspection, death, timing, mouse conversion and click navigation regressions.

Godot 4.6.3 headless tests and startup passed. The initial headless cursor-warp test could not move the platform pointer; event-based input handling/tests resolved that limitation. Manual visual testing remains outstanding.
