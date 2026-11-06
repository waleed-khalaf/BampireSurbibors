# 17: Influencer selfie flash

**What to build:** From 2:00, Influencers keep their distance and fire a dodgeable selfie flash that briefly slows Shireen.

**Blocked by:** 10 (Spawn timeline and Crypto Bro swarms)

**Status:** ready-for-agent

- [ ] Data: HP 15, speed 50, drain 5/s, cash 3, starting at 2:00.
- [ ] Behavior: keeps about 120 px from Shireen. Every 4 s a telegraphed flash goes off, and a hit slows her 40% for 1.5 s.
- [ ] View: telegraph, flash effect, a slowed indicator on Shireen, and a draft sprite.
- [ ] Tests: the distance he keeps; the flash timing; the slow amount and duration; a dodged flash has no effect.
