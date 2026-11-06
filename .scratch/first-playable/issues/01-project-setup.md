# Project setup

Status: ready-for-agent
Blocked by: none

Create the Godot 4.7 project in the repo root.
- `project.godot` named "Habibi, Get Closer". Folders: `scenes/`, `scripts/`, `data/`, `assets/sprites/`, `assets/audio/`, `tools/`.
- Display: viewport 640×360, stretch mode `viewport`, integer scale, window 1280×720, nearest-neighbor texture filtering.
- Input map: `move_left/right/up/down` (WASD and arrows), `ui_accept` (Enter), `pause` (Esc), `toggle_fullscreen` (F11), `debug_snapshot` (F12).
- F11 toggles fullscreen from a global autoload.
- Check: `godot --headless --check-only` / an editor import runs with no errors.
