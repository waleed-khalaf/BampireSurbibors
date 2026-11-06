# 23: Sound effects and music

**What to build:** The game has sound. Every Run event plays a sound (placeholder blips until real effects exist), and a chiptune darbuka loop plays in time with the beat clock, switching to a boss track when the Yacht Sheikh arrives.

**Blocked by:** 16 (Darbuka Drop)

**Status:** ready-for-agent

- [ ] An audio director maps Run events to sounds. Any missing asset falls back to a placeholder blip.
- [ ] jsfxr sound effects for hits, dazzles, pickups, level-ups, lamps and UI.
- [ ] A music loop and a boss track, with the music switching when the boss arrives. Placeholder loops are fine until the BeepBox tracks exist.
- [ ] The music stays synced to the Run's beat clock, with the BPM taken from config.
- [ ] Verified by playing.
