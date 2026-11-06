# 11: Supercar Guy charges

**What to build:** From 1:00, Supercar Guys stop, flash a visible telegraph, then charge in a straight line, so Shireen has to dodge.

**Blocked by:** 10 (Spawn timeline and Crypto Bro swarms)

**Status:** ready-for-agent

- [ ] Data: HP 20, charge speed 260, drain 15/s, cash 3, starting at 1:00 on the timeline.
- [ ] Behavior: approach, stop, 0.8 s telegraph, straight-line charge, recover, repeat.
- [ ] The charge direction locks when the telegraph starts, so the charge can be dodged.
- [ ] View: a telegraph indicator and a draft Supercar Guy sprite.
- [ ] Tests: telegraph duration; direction locked at telegraph start; arrival from 1:00.
