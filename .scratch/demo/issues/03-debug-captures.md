# 03: Debug captures

**What to build:** While you play a dev build, the game saves a screenshot every 5 seconds and keeps the last 60. Pressing F12 saves a screenshot plus a state dump, so Claude can see what happened when you report an issue.

**Blocked by:** 02 (Shireen walks on endless Giza sand)

**Status:** ready-for-agent

- [ ] Active only in debug builds.
- [ ] Rolling capture every 5 s into the gitignored capture folder, keeping the newest 60.
- [ ] F12 saves a screenshot plus `state.txt`, named by date and time. The dump covers the run time, Shireen's position, fps, everything registered by state providers, and the last 20 log lines and errors.
- [ ] Later systems register state through a provider API (Patience, weapon, passives, admirer count) without changing the capture service.
- [ ] An API takes a snapshot with a reason, for later tickets' run ended, victory and error captures.
- [ ] Verified by playing: the files appear and are readable.
