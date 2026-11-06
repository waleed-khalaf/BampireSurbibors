# Level-up buff cards

Status: ready-for-agent
Blocked by: 09

- Run: on level-up, enter the level-up phase (simulation paused) and offer 3 random unmaxed buffs from the weapon's 4 tracks (Zills per design §6.1). Picking a card by index applies it through the stat model. When everything is maxed, offer "Big tip" and "Sip of tea". Levels 5, 10 and 15 are the ability-level hook (buff cards until milestone 5).
- View: the card screen, navigated with the arrows and Enter, with each card showing the track, the next rank and the change.
- Tests: 3 distinct unmaxed buffs offered; the pick applies the change; maxed tracks are excluded; fallbacks; the simulation doesn't advance during the choice.
