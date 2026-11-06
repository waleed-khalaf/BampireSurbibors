# Debug captures

Status: ready-for-agent
Blocked by: 01

A `DebugCapture` autoload, active only in debug builds (`OS.is_debug_build()`).
- Rolling: save a viewport screenshot every 5 s to `debug_captures/rolling/`, keeping the newest 60.
- F12: save `debug_captures/snap_<timestamp>.png` plus `snap_<timestamp>.txt` (run time, Shireen's position and Patience, weapon with buffs/abilities, passives, admirer count, fps, the last 20 log lines and errors).
- `DebugCapture.snapshot(reason)` for automatic captures (game over now; victory and errors later).
- Systems register state through a small provider API, so the capture doesn't depend on specific scenes.
- File names use local date and time. The folder is gitignored.
