# 01: Project boots

**What to build:** You open the project in Godot and press F5. A crisp 640×360 window, scaled to 1280×720, shows a run timer ticking up. A bare Run simulation drives the timer, and one command runs the test suite headless.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [x] The Godot 4.7 project "Habibi, Get Closer" opens with no errors.
- [x] Display: 640×360 base, `viewport` stretch mode with integer scaling, a 1280×720 window, nearest-neighbor filtering. F11 toggles fullscreen from any screen.
- [x] Input actions exist for move (WASD and arrows), accept (Enter), pause (Esc), fullscreen (F11) and debug snapshot (F12).
- [x] A Run can be constructed from config (seed, play-area extents) and advanced with `step` on a fixed 60 Hz timestep. Its state snapshot exposes the run time.
- [x] The view accumulates frame time into fixed steps and displays the run time.
- [x] GdUnit4 is installed (ask the user before downloading it), and a single command runs the suite headless.
- [x] Test: the same seed and inputs produce identical snapshots.
- [x] A short README explains how to open the project, play (F5) and run the tests.

## Comments

**2026-11-06 (Claude):** Implemented. All acceptance criteria checked: 5 headless tests pass via `run_tests.cmd`; window, stretch, filtering, input map and F11 verified in a running game.

**2026-11-06 (Claude):** Review follow-up. The determinism test exists and compares every step, but it can't fail yet: nothing reads the seed or the move direction, and the snapshot holds only time and tick. It starts to bite once ticket 02 puts Shireen's position in the snapshot. The F12 input action is named `debug_capture` to match the glossary. Only F11 is wired up so far; the README says which ticket wires each of the other keys.
