# AlphaPlanet — Prototype 3

Godot 4 / GDScript turn-based hex roguelite prototype. Tested with Godot 4.6.3. No external dependencies or assets.

## Launch

Download or clone this branch, import `project.godot` into Godot 4, and press **F5**. Alternatively, from the project directory:

```sh
godot --editor --path .
# Run directly:
godot --path .
```

## Controls and layout

Controls are unchanged: **Q/E** upper diagonals, **A/D** horizontal, **Z/X** lower diagonals; **S** examines the hovered tile, **F** fires at a hovered enemy, **Space** waits, **Esc** cancels navigation, **R** restarts after Game Over. Click an open tile to follow an A* route; bump or click an adjacent enemy to attack in melee. Each step rechecks occupancy. Invalid actions are free.

The map occupies a dedicated viewport to the left of a 280-pixel sidebar and above a 180-pixel event log (dimensions adapt for smaller windows). Camera-aware mouse conversion uses the map viewport's transform. UI panels do not cover the map. Scroll the item list and log independently. The log follows new entries while at the bottom; scrolling up preserves review position. It retains the latest 300 categorized messages.

Click **Inventory** to open the item window; click its item rows to pin/unpin, then Close or the window close button. Opening it cancels navigation and blocks gameplay keyboard input. Quick-access rows select items. Pinned items appear first; quantity, equipped, and selected markers derive from shared character state. Group buttons **1**, **2**, **3** select Plasma Pistol, Combat Knife, and Unarmed respectively at no time cost. These are mouse buttons, not new keyboard bindings. F requires the pistol group; melee remains available in all groups with the existing five damage. Selecting a quick-access item does not equip it or consume it.

## Combat

All attacks use an independent 3d6 roll-under check: total <= base skill + modifiers. Player ranged skill is 12, melee 11, Stalker combat 10. Effective skill is never clamped; there are no automatic or critical outcomes or defense rolls. The result includes individual dice, total, base skill, named modifiers, effective skill, success, and signed margin. Production rolls are random; tests inject dice callables.

Successful melee hits deal 5, pistol hits 3, and Stalker hits 2. Misses deal zero but still spend the valid attack's time. Movement, melee and wait cost 100; pistol attacks cost 120. Pistol range remains five hexes with deterministic wall-blocked LOS. Invalid targeting and examination cost zero. There is no time advancement while thinking or during visual animations. Dead enemies leave occupancy and the scheduler immediately; nonblocking remains can be examined.

## Major modules

| Path | Responsibility |
| --- | --- |
| `world/game.gd` | Input and gameplay coordination, attack checks, shared damage/death handling |
| `world/hex_math.gd`, `hex_grid.gd`, `hex_pathfinder.gd` | Axial math, terrain/occupancy/remains, A* |
| `world/hex_sight.gd`, `ranged_targeting.gd` | Symmetric deterministic LOS and target validation |
| `world/hex_inspection.gd` | Live tile/entity/remains descriptions |
| `world/skill_check.gd` | Injectable 3d6 checks and complete result records |
| `world/turn_scheduler.gd` | Discrete chronological scheduling with per-actor intervals |
| `world/event_log.gd` | Bounded categorized event stream, independent of UI |
| `data/character_state.gd` | Stable item IDs, skills, selection, pins, loadouts, appearance and extensible anatomy |
| `entities/` | Player/Stalker HP and movement presentation |
| `ui/hud.gd` | Permanent viewport/sidebar/log layout and inventory modal |
| `ui/portrait.gd` | Placeholder portrait driven by appearance data |
| `rendering/` | Hex polygons and visual-only shot beam |
| `tests/` | Grid, movement, combat, ranged, UI/state and rules regression suites |

Anatomy is a list of independent part records: ID, condition, injuries, armor coverage, replacement, mutations, and impairment. Initial definitions contain six humanoid parts but accept extra/missing parts. Appearance separates body-part references, equipment and visual layers. Neither is a second damage system. HP remains the sole active injury mechanic. No save format is promised.

## Validation

On a fresh checkout, import first to populate global class metadata:

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script tests/run_tests.gd
godot --headless --path . --script tests/smoke.gd
godot --headless --path . --script tests/combat_tests.gd
godot --headless --path . --script tests/ranged_tests.gd
godot --headless --path . --script tests/prototype3_tests.gd
godot --headless --path . --quit-after 60
```

Results: 933 grid checks, 34 combat checks, 24 ranged/inspection checks, 520 Prototype 3 checks, and scene movement smoke passed. Legacy damage regressions inject successful dice; new tests explicitly exercise misses, successful single damage application, modifiers, equality and unclamped skills. UI tests cover inventory blocking, pin ordering, loadouts, bounded events, and targeting after resizing. Headless startup and editor validation also run. Manual visual and scrolling UX validation remains outstanding.

In restricted cloud shells use writable XDG directories under `/tmp/alphaplanet-godot/{data,config,cache}`. Editor validation needs permission for local editor sockets. An initial redundant SubViewport size assignment produced a warning; removing it lets the stretching container own viewport sizing.

## Deferred features

Item effects, ammo/reload, armor, defense rolls, critical results, body-part injuries, full modular character sprites, mutation/cybernetic gameplay, procedural generation, and save compatibility are not implemented. Energy is a labeled placeholder. The inventory provides selection/pinning and sample equipment groups only. Art remains simple shapes.
