# 06: Zills dazzle admirers

**What to build:** Shireen's Zills fire by themselves at the nearest admirer. Enough hits dazzle him: he swoons with a heart pop and wanders off heartbroken.

**Blocked by:** 04 (Dowry Uncles chase Shireen)

**Status:** ready-for-agent

- [ ] Weapon framework: one weapon per run, configured by data (base stats, 4 buff tracks, an ability list), exposing ability hooks (stat modifiers, on-fire, on-hit, every-Nth, periodic) for later tickets.
- [ ] A shared stat model with base values plus additive and multiplicative modifiers.
- [ ] Zills base: 1 zill at the nearest admirer every 1.2 s, damage 10, pierce 0. Zills are data records, and hits are checked through the spatial grid.
- [ ] Dazzle at 0 HP: the admirer stops draining and blocking immediately, swoons, walks off screen and is removed. The dazzled count goes up.
- [ ] View: zill sprite, swoon frame, heart pop.
- [ ] Weapon state appears in the F12 state.
- [ ] Tests: fire rate and nearest-target choice; correct hits to dazzle; pierce; dazzled admirers don't drain.
