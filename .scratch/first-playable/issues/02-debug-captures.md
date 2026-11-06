# Debug capture service

Status: ready-for-agent
Blocked by: 01

A global service, active in dev builds only, living in the view layer.
- Rolling screenshot every 5 s into the capture folder, keeping the newest 60.
- F12: a screenshot plus `state.txt` with the run time, Shireen's position and Patience, weapon with buffs/abilities, passives, admirer count, fps, and the last 20 log lines and errors.
- `state.txt` is built from whatever state providers are registered (the Run view registers the Run's state snapshot), so the service doesn't depend on specific scenes.
- An API to snapshot with a reason, used for run ended now and errors later.
- Not covered by automated tests; verify by playing.
