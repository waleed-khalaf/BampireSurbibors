# 07: Cash, level bar and karkadeh tea

**What to build:** Dazzled admirers drop cash that flies to Shireen when she gets close and fills a level bar. Rare karkadeh tea drops restore Patience.

**Blocked by:** 05 (Patience and "You said yes."), 06 (Zills dazzle admirers)

**Status:** ready-for-agent

- [ ] Run: each dazzle drops cash worth the admirer's value. Cash inside the pickup radius (24 px, from data) flies to her. The leveling curve `5 + 3·(n−1)` comes from data and emits leveled-up events.
- [ ] Karkadeh tea drops at ~1% per dazzle (from data) and restores 30 Patience, capped at the maximum.
- [ ] Pickups are pooled data records, so hundreds of them don't hurt fps.
- [ ] View: cash sprites by value (3 sizes), a tea sprite, a HUD level bar and level number.
- [ ] The defeat screen shows the real cash collected and admirers dazzled.
- [ ] Tests: drop values; pickup radius; level thresholds; tea restore and its cap; drop rolls are deterministic by seed.
