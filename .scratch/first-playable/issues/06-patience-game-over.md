# Patience, drain and game over

Status: ready-for-agent
Blocked by: 05

- Shireen has Patience 100. Each touching admirer drains its `drain`/s.
- A HUD Patience bar.
- At 0: freeze the run, take a `DebugCapture.snapshot("game_over")`, and show the "You said yes." screen with a placeholder wedding photo, the stats (time, admirers dazzled, cash), and Enter to restart.
- Record which admirer type touched her last (for per-type photos later).
