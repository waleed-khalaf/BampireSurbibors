# End-of-demo checks

Checks parked until the demo is built, usually because they need something the project doesn't have yet (exported builds, all content in place). Work through this list before calling the demo done. Tick each one and note the date and result; add new ones with the ticket they came from.

## Exported builds

These need Godot's export templates: in the editor, **Editor → Manage Export Templates → Download and Install**, then a Windows Desktop preset under **Project → Export**. `export_presets.cfg` and `/builds/` are gitignored.

- [ ] **A release build makes no debug captures** (ticket 03, [#3](https://github.com/waleed-khalaf/BampireSurbibors/issues/3), criterion "Active only in debug builds"). Export with **Export With Debug** unticked, play for over 10 seconds and press F12. Pass: no `debug_captures` folder appears next to the game or in `%APPDATA%\Godot\app_userdata\Habibi, Get Closer\`, and no "Debug capture saved" message shows. So far this is confirmed only by reading the code: `src/debug/debug_capture.gd` switches itself off when `OS.is_debug_build()` is false.
- [ ] **A debug export saves captures to the user data folder** (ticket 03). Export with **Export With Debug** ticked, play for over 10 seconds and press F12. Pass: `%APPDATA%\Godot\app_userdata\Habibi, Get Closer\debug_captures\` holds `rolling\` screenshots and a snapshot folder with `screenshot.png` and `state.txt`. Confirmed so far only from the code and the project settings.
