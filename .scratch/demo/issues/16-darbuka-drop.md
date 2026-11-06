# 16: Darbuka Drop

**What to build:** Darbuka Drop becomes selectable at weapon select. Drum-beat blasts land around Shireen in time with a beat clock, with their own buffs and abilities.

**Blocked by:** 09 (Title, weapon select and pause), 12 (Ability levels and Zills abilities)

**Status:** ready-for-agent

- [ ] Review the draft values and abilities with the user before building (design §6.5).
- [ ] A Run beat clock driven by the configured music BPM, exposed in the state snapshot, so ticket 23 can sync the music to it.
- [ ] Base: every 1.6 s, 1 blast at a random point within 160 px, radius 36 px, damage 20.
- [ ] Buff tracks: Damage, Beat rate, Drops, Blast radius.
- [ ] Abilities: Homing Beat (the weakness fix), Doum-Tek, Drumroll, Echo, On the Beat (+25% damage on the downbeat).
- [ ] View: blast telegraphs and impact visuals.
- [ ] Tests: the beat clock matches the BPM; base behavior, each buff track and each ability, all through the Run.
