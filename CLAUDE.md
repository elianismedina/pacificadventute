# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Pacific Kids** is a Godot 4.6 educational game for children. It uses the GL Compatibility renderer (mobile-friendly) and targets a 1600×900 viewport with canvas_items stretch mode.

## Running & Developing

This is a Godot project — there is no build script or CLI test runner. All development happens through the Godot Editor.

- **Run project**: Open in Godot 4.6 editor and press F5 (or use the MCP `mcp__godot__run_project` / `mcp__godot__launch_editor` tools)
- **Main scene**: `scenes/main_menu.tscn` (uid: `uid://cttm7sbnpyxfw`)
- **Godot version**: 4.6, GL Compatibility renderer

## Architecture

### Scene Navigation Flow

```
main_menu.tscn
  └─ levels_map.tscn  (level selection hub)
       ├─ scenes/levels/{pier,forest,mural,celebration}.tscn  (simple levels)
       ├─ games/manglar level/board.tscn  (sliding puzzle mini-game)
       └─ games/mural_level/murallevel.tscn  (coloring mini-game)
```

All scene transitions go through the **GameLoader** autoload (`scripts/autoloads/game_loader.gd`), which overlays `scenes/LoadingScreen.tscn` and uses threaded resource loading. Always use `GameLoader.load_scene(path)` for navigation — never call `change_scene_to_file()` directly unless GameLoader is unavailable.

### Autoloads (Singletons)

- **GameLoader** (`scripts/autoloads/game_loader.gd`) — the only autoload. Handles all scene transitions with a loading screen. Emits `progress_changed` and `load_finished` signals.
- `loading_screen.gd` is *not* an autoload; it is the script attached to the LoadingScreen scene that GameLoader instantiates.

### Back Navigation

`scripts/BackButton.gd` is a reusable `Button` script that always navigates back to `levels_map.tscn`. It tries GameLoader first, then falls back to `change_scene_to_file()`. Attach it to any Button node in a level scene that should return to the map. The script was recently moved from `games/manglar level/` to `scripts/` — use the canonical path at `scripts/BackButton.gd`.

### Mini-Games

**Manglar level** (`games/manglar level/`): A 4×4 sliding tile puzzle.
- `board.gd` is the active controller. It dynamically sizes tiles to fill 90% of the smaller viewport dimension, validates solvability with a permutation-parity algorithm, accepts WASD/Arrow keyboard input (input map: `move_left/right/up/down`), and emits `game_started`, `game_won`, `moves_updated(int)`.
- `mangrove_puzzle.gd` is an alternative/experimental controller that is not wired into the main navigation. `manglarscript.gd` appears unused.

**Mural level** (`games/mural_level/`): A painting / coloring game.
- `Scripts/coloring_games.gd` handles object zooming (click to focus, QUINT easing 0.5 s), a primary-color palette (blue/red/yellow + black/white), color mixing by RGB averaging, and painting via physics point queries.
- Paintable areas must be in the `paintable` group **or** have node names starting with `patch_`. Focusable object roots must be in the `interactable_root` group **or** start with `Object_`.

### Simple Levels

`scripts/level_placeholder.gd` is a base class for levels that have no custom logic. It exports a `back_scene_path` variable and handles back navigation. Use this for pier, forest, etc.

## Key Conventions

- Scene paths with spaces (`games/manglar level/`) are intentional — keep them as-is to avoid breaking UIDs.
- All textures use nearest-neighbor filtering (pixel-perfect). Set `texture_filter = TEXTURE_FILTER_NEAREST` on new sprites/viewports.
- Audio: background music in `main_menu.gd`; button SFX played before scene transitions (wait for the audio to finish before loading).
- The project uses UIDs extensively. After moving or renaming scenes/scripts, run `mcp__godot__update_project_uids` (or use the editor's "Fix Broken UIDs" option) to keep references valid.
