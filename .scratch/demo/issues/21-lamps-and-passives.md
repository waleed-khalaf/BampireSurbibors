# 21: Lamps and passives

**What to build:** A genie lamp appears off-screen about every 50 seconds, with an arrow at the screen edge pointing to it. Walking over it plays a lamp-rubbing reveal and grants a random passive.

**Blocked by:** 08 (Level-up buff cards)

**Status:** ready-for-agent

- [ ] Run: lamp spawns about every 50 s (from data), placed off-screen. Walking over one enters the lamp-reveal phase (simulation paused), and continuing resumes the run.
- [ ] The passive roll is random: a new passive at rank 1, or +1 rank on one she has, up to 3.
- [ ] All 5 passives work through the stat model: Comfy Slippers, Kohl Eyeliner, Big Hair, Oud Perfume, Gold Bangles.
- [ ] When every passive is maxed, a lamp gives a cash pile and a full Patience refill.
- [ ] View: the lamp sprite, a HUD edge arrow to the nearest lamp, and the genie-lamp rubbing animation before the reveal.
- [ ] Passives appear in the F12 state and on the end screens.
- [ ] Tests: the spawn interval; the roll rules and the rank-3 cap; the maxed fallback; each passive's effect; the simulation is paused during the reveal.
