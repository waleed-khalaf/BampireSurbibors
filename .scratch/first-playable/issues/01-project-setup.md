# Project setup and test harness

Status: ready-for-agent
Blocked by: none

- Create the Godot 4.7 project "Habibi, Get Closer" in the repo root.
- Display: 640×360 viewport, `viewport` stretch mode with integer scaling, a 1280×720 window, nearest-neighbor filtering.
- Input map: move (WASD and arrows), accept (Enter), pause (Esc), fullscreen (F11), debug snapshot (F12). A global F11 fullscreen toggle.
- Install GdUnit4 as an addon. It's a third-party download, so ask the user before fetching it. Add a one-line command to run the suite headless, and one passing smoke test.
- Done when the editor opens with no errors and the headless test command passes.
