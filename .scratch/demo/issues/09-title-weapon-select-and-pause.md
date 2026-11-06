# 09: Title, weapon select and pause

**What to build:** The game opens on a title screen, then weapon select, with weapons not yet built greyed out. Esc pauses with Resume, Restart and Quit, and each run opens with Shireen's "Habibi, get closer".

**Blocked by:** 05 (Patience and "You said yes."), 06 (Zills dazzle admirers)

**Status:** ready-for-agent

- [ ] A title screen with "Habibi, Get Closer". Enter goes to weapon select.
- [ ] Weapon select lists all 5 weapons with short descriptions. Only implemented weapons can be picked, and the choice goes into the Run config.
- [ ] Esc pause menu: Resume, Restart (a new run with the same weapon) and Quit (back to the title). The simulation isn't stepped while paused.
- [ ] A "Habibi, get closer" text pop at the start of each run.
- [ ] "Play again" on the end screens goes to weapon select.
- [ ] Every screen is navigable with the keyboard alone.
- [ ] Tests: a Run is constructed with the chosen weapon ID; an unknown weapon ID is rejected.
