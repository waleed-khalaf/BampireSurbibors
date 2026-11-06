# 04: Dowry Uncles chase Shireen

**What to build:** Dowry Uncles spawn just off-screen in growing numbers and walk toward Shireen. They spread out instead of stacking into one blob.

**Blocked by:** 02 (Shireen walks on endless Giza sand)

**Status:** ready-for-agent

- [ ] Admirer types are data (Dowry Uncle: HP 30, speed 40, drain 10/s, cash 2), with a behavior chosen by ID through the content registry.
- [ ] Admirers are data records inside the Run, driven by a chase behavior.
- [ ] A spawn director places admirers in a ring just outside the play area around Shireen, at a rate that ramps over time.
- [ ] A spatial grid keeps admirers separated.
- [ ] View: a pooled batch renderer draws the Uncles (2-frame walk, flip by direction), using a generated draft Uncle sprite.
- [ ] The admirer count appears in the F12 state.
- [ ] Tests: spawn positions are off-screen; Uncles close the distance to Shireen; separation holds in a dense crowd; 300 admirers stay within the step-time budget (calibrated once and recorded in the test).
