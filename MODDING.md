# Your first AlphaPlanet weapon mod

Mods contain **JSON data, not code**. No Steam installation is needed. The normal game retains its existing UI, controls and 3d6 rules.

1. Open the project in Godot. Use **Project → Open User Data Folder**, then create a folder called `mods` if needed.
2. Use Mod Manager → Install Example Mod, or copy the entire `examples/railgun` folder into that `mods` folder (not both). It must contain `mod.json` and `content.json` directly, not inside another nested folder.
3. Restart the game. Load diagnostics appear in the event log. Enable the Railgun and Apply Changes in Mod Manager. It does not change normal starting equipment.
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

## Main menu and local installation hotfix

The example used to load directly from `res://examples/railgun`, so the writable Mods folder could be empty despite the Railgun appearing in the list. That bundled folder is now only an installation template, not active content.

### Install and use the example without programming

1. Start the game and open **Mod Manager**.
2. Click **Install Example Mod**. It copies `mod.json` and `content.json` into `user://mods/experimental_railgun`. Existing destination folders are never overwritten. If an earlier manual installation exists elsewhere under Mods, remove one duplicate copy yourself after checking your changes.
3. Click **Open Mods Folder** to see the actual files. This is the same writable directory scanned by the loader. Its operating-system path is shown in details, and Godot resolves it for both editor and exported applications.
4. Tick Experimental Railgun and click **Apply Changes**. The selection persists in `user://enabled_mods.json`. Refresh preserves pending selections; it does not apply them. Missing dependencies or invalid content prevent Apply from saving that combination.
5. Start **New Run**, press **Esc** when no movement route is active, and choose **Development Tools**.
6. Select Experimental Railgun by its item or weapon ID, click **Grant Item**, then return to Pause and Resume. The sidebar updates immediately; select the new equipment group (normally 4) to equip it. Repeated grants increase quantity rather than adding duplicate groups.
7. Hover an enemy within nine hexes with clear LOS and press F. The combat log shows a 3d6 check against skill 10. A success deals 12 damage; a miss deals none. Either valid attack costs 180 time units. A miss is not a loading failure.
8. Return to the menu, disable the mod, Apply, and start a new run. It will be absent from Development Tools and the active registry; the base Plasma Pistol remains available.

Development Tools and the older `--dev-item=namespace:item` option are gated by `OS.is_debug_build()`. Use the editor or a debug export for testing. A release export has neither accessible grants nor the pause-menu tool button. The tool lists actual registered items and weapons, stable IDs and their source namespaces; diagnostics show weapon counts, enabled mod IDs, and registry errors. Granting never advances time.

### Sources, files, and errors

**Base Game** is packaged in `res://content/base` and required. **Bundled Example** is the installable template, clearly labeled in the menu. **Local Mod** means a folder under `user://mods`; the details show its real path. Additional trusted discovery directories use the label **External Directory**. Steam Workshop is reserved for a future adapter and is not integrated.

The installer stages the two required JSON files and renames the completed folder into place. It refuses to overwrite any existing destination or abandoned staging directory. User files are never silently replaced. The installed example loads independently of the bundled template.

To create your own weapon, copy an installed mod folder, give the manifest a unique ID, update its content ID prefixes, and edit the weapon numbers in `content.json` with a text editor. Keep `base:ranged` and declare dependency `base`. Use the schemas and examples above for valid punctuation and fields. Refresh, enable, Apply, then use Development Tools to grant your registered content. Do not reuse another installed mod's ID.

Malformed files, unsupported API versions, duplicate IDs, missing dependencies, cycles and registration errors appear in Mod Manager diagnostics. Failed Apply preserves the previous selection. Removed enabled mods produce a diagnostic, while valid base content remains playable. No hot-reloading occurs inside a run.

### Exports and manual checks

`export_presets.cfg` includes base/template/schema JSON in the Linux export resource filters; other desktop presets must retain those JSON filters. No source path is written by the installer. Runtime installation always uses writable `user://mods`.

Automated `tests/local_install_tests.gd` installs into an isolated writable user folder, verifies no overwrite, real discovery, selection persistence, pause tools, item grants, data-defined Railgun hits/misses, duplicate handling and safe removal. Existing gameplay and loader tests remain available. Settings/fullscreen tests were intentionally not run for this hotfix.

Manual checks: click Install and Open Mods Folder on your desktop; inspect the two JSON files; enable/apply and reopen the app; grant via Pause → Development Tools; equip and fire; disable and start a fresh run. Check that release exports hide Development Tools. Native folder opening and standalone executable behavior require desktop testing; automated resource packaging does not establish those behaviors. Fullscreen is already confirmed and is outside this hotfix.
