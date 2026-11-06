# 08: Level-up buff cards

**What to build:** On level-up the game pauses and offers 3 buff cards for Zills. You pick one with the arrows and Enter, and it takes effect. This completes the **first playable**.

**Blocked by:** 07 (Cash, level bar and karkadeh tea)

**Status:** ready-for-agent

- [ ] Run: a level-up phase pauses the simulation and offers 3 distinct random unmaxed buffs from the weapon's 4 tracks. Picking one by index applies it through the stat model.
- [ ] All four Zills buff tracks work as specified in design §6.1.
- [ ] Maxed tracks are excluded. When every track is maxed, the cards are Big tip and Sip of tea.
- [ ] Several level-ups gained at once are offered one after another.
- [ ] A hook for ability levels 5, 10 and 15 exists (it shows buff cards until ticket 12).
- [ ] View: a card screen showing the track name, the next rank and what changes, navigated with the arrows and Enter.
- [ ] Buffs appear in the F12 state.
- [ ] Tests: offers are distinct and unmaxed; each Zills track's effect; the fallbacks; no simulation progress during the choice; queued level-ups.
- [ ] The user plays the first playable and gives feedback on the feel before later tickets begin.
