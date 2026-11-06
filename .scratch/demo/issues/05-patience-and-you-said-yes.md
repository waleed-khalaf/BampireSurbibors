# 05: Patience and "You said yes."

**What to build:** Admirers touching Shireen drain her Patience. When it hits zero, the run ends on "You said yes." with a placeholder wedding photo and stats, and Enter starts a new run.

**Blocked by:** 03 (Debug captures), 04 (Dowry Uncles chase Shireen)

**Status:** ready-for-agent

- [ ] Run: Patience comes from data (100). Each touching admirer drains its own rate per second. A run-ended event carries the defeat outcome and the last-touching admirer type, and the simulation stops after the end.
- [ ] A HUD Patience bar.
- [ ] Defeat screen: "You said yes.", a placeholder photo, time survived, admirers dazzled and cash collected. Enter restarts.
- [ ] A debug capture is taken automatically when a run ends.
- [ ] Patience appears in the F12 state.
- [ ] Tests: the drain rate matches the data with one and with several touching Uncles; defeat at 0; the correct last-touching type; no drain after the end.
