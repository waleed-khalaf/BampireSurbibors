# 01: Project boots

**What to build:** You open the project in Godot and press F5. A crisp 640×360 window, scaled to 1280×720, shows a run timer ticking up. A bare Run simulation drives the timer, and one command runs the test suite headless.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] The Godot 4.7 project "Habibi, Get Closer" opens with no errors.
- [ ] Display: 640×360 base, `viewport` stretch mode with integer scaling, a 1280×720 window, nearest-neighbor filtering. F11 toggles fullscreen from any screen.
- [ ] Input actions exist for move (WASD and arrows), accept (Enter), pause (Esc), fullscreen (F11) and debug snapshot (F12).
- [ ] A Run can be constructed from config (seed, play-area extents) and advanced with `step` on a fixed 60 Hz timestep. Its state snapshot exposes the run time.
- [ ] The view accumulates frame time into fixed steps and displays the run time.
- [ ] GdUnit4 is installed (ask the user before downloading it), and a single command runs the suite headless.
- [ ] Test: the same seed and inputs produce identical snapshots.
- [ ] A short README explains how to open the project, play (F5) and run the tests.
