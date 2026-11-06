# First playable (milestones 1–3)

Status: ready-for-agent

Goal: the smallest build that answers "is this fun?". Shireen walks around endless Giza sand, Dowry Uncles swarm her, her Zills dazzle them, they drop cash, and cash leads to buff cards. Losing all Patience ends on "You said yes."

Source of truth: `docs/design.md` (sections 2, 4, 5, 6.1, 7, 9, 12, 13) and `GLOSSARY.md`.

## In scope
- Godot 4.7 project, display settings (640×360, integer scaling, windowed 1280×720, F11)
- Debug captures (rolling, F12 snapshot plus `state.txt`, auto on game over)
- Draft pixel sprites: Shireen, Dowry Uncle, cash, zill, sand tile
- Movement, camera, endless sand
- Dowry Uncle spawning and crowd separation
- Patience, drain, game-over screen
- Zills (base weapon plus its 4 buff tracks, no abilities yet)
- Cash drops, pickup, level bar, level-up card screen

## Out of scope (later milestones)
Weapon select, the timer, other admirers, the boss, abilities, lamps, passives, audio, victory.

## Done when
The user can press F5, play a run that ends in "You said yes.", and debug captures appear in `debug_captures/`.
