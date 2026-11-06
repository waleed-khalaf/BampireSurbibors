# Patience, drain and "You said yes."

Status: ready-for-agent
Blocked by: 06

- Run: Patience 100, drained per second by each touching admirer that isn't dazzled. Records the last-touching admirer type. A run-ended event with the defeat outcome.
- View: a HUD Patience bar, and the "You said yes." screen with a placeholder wedding photo and stats (time, admirers dazzled, cash). Enter restarts. A debug capture on run ended.
- Tests: the drain rate matches the data; dazzled admirers don't drain; defeat at 0 with the correct last-touching type.
