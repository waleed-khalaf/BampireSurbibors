# 24: Barks

**What to build:** Admirers shout short Gulf-flavored Franco-Arabic barks, and Shireen answers in Egyptian, as text pop-ups with optional recorded voice lines.

**Blocked by:** 23 (Sound effects and music)

**Status:** ready-for-agent

- [ ] The Run emits bark events (speaker type, line category) with cooldowns so barks never spam.
- [ ] Admirer categories: spawning, near Shireen, dazzled. Shireen's categories: run start, level-up, victory, defeat.
- [ ] Bark lines live in data and follow the tone rules in design §1.
- [ ] View: short text pop-ups above the speaker. A recorded voice line plays when an audio file exists for it.
- [ ] Tests: bark rate limiting; barks are deterministic by seed.
