# Your first AlphaPlanet weapon mod

Mods contain **JSON data, not code**. No Steam installation is needed. The normal game retains its existing UI, controls and 3d6 rules.

1. Open the project in Godot. Use **Project → Open User Data Folder**, then create a folder called `mods` if needed.
2. Copy the entire `examples/railgun` folder from this repository into that `mods` folder. It must contain `mod.json` and `content.json` directly, not inside another nested folder.
3. Restart the game. Load diagnostics appear in the event log. A valid Railgun mod is now registered, but does not change your normal starting equipment.
4. For a development playtest, run from the project directory:

   ```sh
   godot --path . -- --dev-item=example_railgun:railgun
   ```

   Select equipment group **4** in the sidebar, hover an enemy, and press **F**. It uses the same LOS and 3d6 attack system as the pistol, with damage 12, range 9, time cost 180, and effective base skill 10. Group 1 still selects the Plasma Pistol.
5. To disable it, move its folder outside `mods` and restart. Content is rebuilt on each load. The development argument reports missing content rather than granting a substitute.

For your own mod, copy the example and change the manifest ID and all matching prefixes (for example `my_mod:railgun`). Give both definitions unique IDs. Change display names freely; IDs should remain stable. Edit damage/range/action_cost/skill_override in a text editor, preserve JSON punctuation, and restart. No weapon-specific GDScript is needed. New ranged weapons currently use `base:ranged` and require `base` as a dependency.

## File format and validation

`content/schemas/mod.schema.json` and `content/schemas/content.schema.json` are JSON Schema documents usable by editors. The runtime performs equivalent required-field/type/range checks plus namespace, duplicate and reference validation. Unknown metadata fields are ignored, not executed. Documents are limited to 1 MiB each.

Manifest fields: `id` (lowercase letter followed by lowercase letters/digits/underscores), `name`, `version` (nonempty version label), `api_version: 1`, and `dependencies` (mod ID strings). `description` and `author` are optional text. Dependency version constraints are not supported yet.

Content files contain `schema_version: 1` and a `definitions` array. Every definition requires `id`, `kind`, `name`. IDs are globally unique `mod_id:local_id`; each part follows the manifest ID syntax. A pack may only define its own namespace. Base and mod content pass through the same registration API.

| Kind | Required additional fields |
| --- | --- |
| `items` | `starting_quantity` (integer >= 0) |
| `weapons` | `item` (item ID), `skill` (skill ID), `damage` (integer >= 0), `range` and `action_cost` (integers >= 1); optional integer `skill_override` |
| `enemies` | `health` and `interval` (integers >= 1), `damage` (integer >= 0), integer `combat_skill` |
| `skills` | integer `base_value` (not clamped) |
| `status_effects`, `upgrades` | optional `description`; schema registration only, no effects executed |

Weapon references must resolve to the correct registry kind in the same pack or a declared dependency. No overrides or patches are allowed. Any invalid definition rejects the entire pack, leaving no partially registered items. Invalid JSON, duplicates, missing dependencies, failed dependencies, and dependency cycles are reported and disabled. Independent valid mods continue loading. Duplicate mod IDs disable all candidates; `base` is reserved for packaged content.

Only the fixed `mod.json` and `content.json` filenames are read. Manifests cannot specify scripts or file paths. Traversal paths, linked local mod directories, linked definition files, inaccessible files and oversized JSON are rejected. External directory paths are trusted discovery inputs, not manifest data.

## Runtime architecture and audit

Previously inventory definitions and skill defaults were in `CharacterState`, pistol statistics in `RangedTargeting`, and enemy statistics in `AlienStalker`. Those representative values now come from `content/base/content.json`, including all five existing item names/quantities. The unarmed/knife-equivalent melee behavior remains five damage for 100 time units, preserving existing rules.

`ContentRegistry` holds definitions and returns deep copies. Runtime inventory instances hold a `content_id` plus mutable quantity; short instance keys such as `pistol` are not content IDs. UI gets display data through `item_view`. Entities hold their definition ID and copy mutable HP and other instance values. Existing skill values (12 ranged, 11 melee), Stalker stats (7 HP, 2 damage, skill 10, interval 100), scheduling, movement, and 3d6 math are preserved. Anatomy and appearance remain the prior structural placeholders.

`ModManager.load_content(external_directories, discover_local, disabled)` starts a fresh registry. It discovers packaged base content and immediate subfolders of `user://mods`, then combines trusted external mod directories. Ready dependencies load in stable lexical order; registration succeeds before dependents become eligible. A future Workshop adapter only supplies installed absolute folder paths to this API. No Steam SDK, downloads, uploads, subscriptions or Workshop publishing are implemented.

## Gameplay event API 1

`game.hooks.emitted(event_name, payload)` is a central synchronous observation signal; payload dictionaries are copied. Mod JSON cannot subscribe or execute callbacks yet. These hooks prepare a future validated effect system, not arbitrary scripting. Actor identifiers are runtime identifiers (`player`, `stalker` in this single-enemy prototype), separate from content IDs.

| Event | Timing and payload |
| --- | --- |
| `on_attack` | After a valid attack's 3d6 roll, before damage: `attacker`, `target`, `result` (full skill-check dictionary) |
| `on_hit` | Only on success, before damage: same payload |
| `on_damage_taken` | After HP changes: `actor`, `damage` (rolled/requested damage, may exceed remaining HP), `health` |
| `on_kill` | Enemy removed from occupancy/scheduler before signal; player marked for Game Over immediately afterward: `actor`, `killer`, optional `content_id` |
| `on_move` | Logical player/enemy step committed (player: before time advances): `actor`, `origin`, `destination` (axial Vector2i) |
| `on_turn_start` | Before processing a committed player action or a due enemy activation: `actor`, `time`, optional `cost` |
| `on_item_used` | Reserved for future item use: intended `actor`, `item_instance`, `content_id`; not emitted while item effects are unimplemented |

## Save compatibility policy

No save system exists yet. `registry.snapshot_metadata()` supplies `{schema_version: 1, mods: [{id, version}]}` for a future save header. Future inventory/entity records must store namespaced content IDs plus instance state, not copied definitions or display names. Compare required mod versions before restoring. Missing IDs return an empty definition plus an explicit diagnostic; UI can label a missing inventory item, but gameplay must refuse to instantiate/use it. Never silently replace a missing modded item with an unrelated base item. A future loader should block incompatible saves or require an explicit recovery choice.

## Testing

Run `godot --headless --editor --path . --quit` first, then `godot --headless --path . --script tests/mod_tests.gd`. Existing test commands remain in README. Mod tests exercise external-directory discovery, data-only Railgun firing, disabling/removal, immutable lookup copies, validation, duplicate rejection, missing dependencies, invalid JSON, deterministic order, event payloads and missing-content policy. Tests create isolated fixtures under `user://mod_tests`, never the real mods directory.
