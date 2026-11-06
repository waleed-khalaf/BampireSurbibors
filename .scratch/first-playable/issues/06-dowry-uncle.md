# Dowry Uncles: spawning, crowding and rendering

Status: ready-for-agent
Blocked by: 04, 05

- Run: admirer data records with Dowry Uncle data (HP 30, speed 40, drain 10/s, cash 2) and a chase behavior.
- A spawn director placing Uncles in a ring just off-screen at a rate that ramps over time.
- A spatial grid for separation so crowds don't stack.
- View: a pooled batch renderer for admirers (frames and flip from state).
- Tests: Uncles spawn off-screen and close in; crowds keep their separation; a performance smoke test with 300 admirers stays within the step-time budget (calibrate once).
