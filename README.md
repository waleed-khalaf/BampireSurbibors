# Habibi, Get Closer

A silly survivors-like made in Godot 4.7. Shireen, an Egyptian belly dancer, dazzles a desert full of over-the-top admirers. The design is in [docs/design.md](docs/design.md), the vocabulary in [GLOSSARY.md](GLOSSARY.md), the demo spec in [docs/demo-spec.md](docs/demo-spec.md) and the work items in [GitHub Issues](https://github.com/waleed-khalaf/BampireSurbibors/issues).

## Open the project

1. Install **Godot 4.7.x, standard build** (not the .NET build). For example: `winget install GodotEngine.GodotEngine`.
2. Start Godot. In the Project Manager, click **Import**, pick this folder's `project.godot` and click **Import & Edit**.
3. The first import takes a few seconds while Godot builds its cache in `.godot/` (gitignored).

## Play

Press **F5** in the editor (or the ▶ button at the top right).

| Action | Keys | Works yet? |
|---|---|---|
| Fullscreen on/off | F11 | Yes |
| Move | WASD or arrow keys | Yes |
| Debug capture (dev builds) | F12 | Yes |
| Accept | Enter | Ticket 05 (restart after "You said yes.") |
| Pause | Esc | Ticket 09 (title, weapon select and pause) |

The keys are all mapped already. For now Shireen can walk around the endless sand while the run timer ticks up.

## Report a bug

While you play from the editor, the game saves a screenshot every 5 seconds to `debug_captures/rolling/` and keeps the newest 60 (about 5 minutes). When something looks wrong, press **F12**: "Debug capture saved" appears at the top left, and a folder like `debug_captures/2026-11-06_14-03-22_f12/` holds `screenshot.png` and `state.txt` (run time, Shireen's position, fps, the seed and the last log lines and errors). Then tell Claude what happened; it reads the captures before changing code. The folder is gitignored and Godot's FileSystem panel doesn't show it, so open it in Explorer. An exported debug build saves its captures to `%APPDATA%\Godot\app_userdata\Habibi, Get Closer\debug_captures\` instead (an exported game can't write into its own files), and exported release builds make no captures.

## Run the tests

From this folder, in PowerShell or a Command Prompt:

```
.\run_tests.cmd
```

This runs the whole GdUnit4 suite headless (no window) and prints `All tests passed.` with exit code 0, or `Tests FAILED` with a non-zero code. It finds Godot through the `GODOT_BIN` environment variable, then `godot` on your PATH, then the winget install folder. HTML and XML reports go to `reports/` (gitignored).

You can also run tests in the editor from the **GdUnit** panel.

## Draw or edit sprites

The sprites in `art/` are code-drawn drafts for you to refine in LibreSprite. [art/README.md](art/README.md) covers the palette, the frame order of each sheet and how to redraw the drafts with `.\generate_sprites.cmd`.

## Tune the game

Tunable numbers live in Godot Resource files under `content/`. Double-click one in Godot's FileSystem panel and edit it in the Inspector. For example, `content/shireen.tres` holds Shireen's move speed. The game checks the content when it starts and shows a message saying what to fix if a value is out of range.

## How the code is laid out

- `src/run/`: the **Run simulation**. Every gameplay rule lives here as plain GDScript objects, with no nodes, input or clock, so it's deterministic and testable headless. See [ADR-0001](docs/adr/0001-run-simulation-seam.md).
- `src/content/`: the **content registry** and the data classes behind the files in `content/`. It loads and checks the content before a Run starts.
- `src/view/`: the **view**, the Godot scenes that draw the Run and feed it keyboard input. They hold no rules.
- `src/debug/`: the **debug capture** service (the `DebugCapture` autoload). Systems add their state to `state.txt` with `DebugCapture.register_provider("Section", callable)`; `DebugCapture.capture("reason")` saves a snapshot from code.
- `art/`: sprite sheets and the shared palette. `tools/sprite_generator/` draws the drafts.
- `tests/`: GdUnit4 tests. Gameplay tests go through the Run only: build one from a seed, step it, check its snapshot. Content tests load data through the content registry and check what it accepts and rejects.
- `addons/gdUnit4/`: the test framework (GdUnit4 v6.2.3), checked in so a fresh clone can run the tests.
