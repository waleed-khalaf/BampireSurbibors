# Habibi, Get Closer: demo

Numbers, content tables and tone rules live in `docs/design.md`. Vocabulary follows `GLOSSARY.md`. The architecture decision is in `docs/adr/0001-run-simulation-seam.md`.

## Problem Statement

The user wants to make a silly, original survivors-like game they can play and show friends, with a comedic twist. **Shireen**, an Egyptian belly dancer, is mobbed in the desert near Giza by over-the-top Gulf **admirers** who want to marry her, hire her and shower her with money. The user has no Godot experience (but knows Python and C#), and they want the game built so it can grow later: more weapons, admirers, characters, maps and maybe saves or other platforms. A pile of tangled scripts would fall over the moment it expanded.

The comedy must land without being mean. The admirers are archetypes of wealth and status, never of bodies, ethnicity or religion. Nothing in the game is menacing or sexual.

## Solution

A Windows-only, keyboard-only Godot 4.7 demo in 32×32 pixel art at 640×360, scaled up by whole numbers.

- **Before the run:** the player picks one of five belly-dance weapons. It's the only weapon for the run, and it fires and aims automatically.
- **During the run:** Shireen survives a 5-minute run against growing crowds of admirers. Her moves **dazzle** them, and a dazzled admirer drops **cash**. Cash levels up the weapon through **buff** cards, plus **ability** cards at levels 5, 10 and 15. Genie **lamps** in the sand grant random **passives**.
- **Endings:** the Yacht Sheikh arrives at 4:00, and dazzling him wins the run ("Shireen stays single!"). If her **Patience** runs out, the run ends on "You said yes."

Under the hood, every gameplay rule lives in one headless, deterministic **Run simulation**. Godot scenes only draw it and feed it keyboard input. Content (weapons, abilities, admirers, passives) plugs in as data plus small behavior classes, so expanding the game means adding content, not rewriting the core. Dev builds capture screenshots and a state dump, so the user can report issues and Claude can see what happened.

## User Stories

### Starting and ending a run
1. As a player, I want to launch the game into a title screen showing "Habibi, Get Closer", so that I know what I'm playing.
2. As a player, I want to choose one of five weapons (Zills, Hip Shimmy, Veil Twirl, Assaya Cane, Darbuka Drop) before each run, so that every run has its own playstyle.
3. As a player, I want each weapon on the select screen to show a short description of how it attacks, so that I can choose knowingly.
4. As a player, I want to navigate every menu with the arrow keys and Enter, so that I never need a mouse.
5. As a player, I want Shireen to say "Habibi, get closer" at the start of a run, so that the title lands as her taunt.
6. As a player, I want a visible run timer, so that I know how close the boss and the end are.
7. As a player, I want the run to last 5 minutes with the Yacht Sheikh arriving at 4:00, so that runs are short enough to replay.
8. As a player, I want admirers to flood in harder and harder if the boss is still up after 5:00, so that a run never just times out.
9. As a player, I want a victory screen saying "Shireen stays single!" when I dazzle the Yacht Sheikh, so that winning feels like a punchline.
10. As a player, I want a "You said yes." screen with a wedding photo of Shireen next to the admirer type that reached her last, so that losing is funny rather than frustrating.
11. As a player, I want both end screens to show the time survived, admirers dazzled, cash collected, weapon, abilities and passives, so that I can compare runs.
12. As a player, I want "Play again" on the end screens to go straight to weapon select, so that retrying is instant.
13. As a player, I want every run to start fresh, with no unlocks or saved progress, so that the demo is simple and fair.

### Moving and surviving
14. As a player, I want to move Shireen in eight directions with WASD or the arrow keys, so that dodging feels responsive.
15. As a player, I want Shireen to face the way she last moved, so that facing-based weapons (the Cane) are predictable.
16. As a player, I want the camera to follow Shireen smoothly with crisp pixels, so that the art stays sharp.
17. As a player, I want endless sand near Giza with decorative props (palm trees, a tourist bus, a sleeping camel, a broken-down Lada taxi, distant pyramids), so that the world feels like a place and never runs out.
18. As a player, I want props to never block my movement, so that I'm never trapped by scenery.
19. As a player, I want a Patience bar that drains while admirers touch Shireen, so that I can tell how close I am to losing.
20. As a player, I want each admirer type to drain Patience at its own rate, so that dangerous types feel dangerous.
21. As a player, I want rare karkadeh tea drops that restore Patience, so that a comeback is possible.

### Weapons and leveling
22. As a player, I want my weapon to fire and aim by itself at the nearest admirer, so that I can focus on moving.
23. As a player, I want the Cane to sweep in Shireen's facing direction instead, so that it has its own skill to master.
24. As a player, I want admirers hit enough times to be dazzled (a swoon, a heart pop, then wandering off heartbroken), so that defeating them is comedic, not violent.
25. As a player, I want dazzled admirers to stop draining Patience and stop blocking others immediately, so that a dazzle always helps me.
26. As a player, I want dazzled admirers to drop cash, with bigger admirers dropping bigger bills, so that tougher targets are worth it.
27. As a player, I want cash within my pickup radius to fly to Shireen, so that collecting it feels good.
28. As a player, I want a level bar that fills with cash, so that I can see the next level-up coming.
29. As a player, I want the game to pause on level-up and offer 3 cards for my weapon, so that I make meaningful choices without pressure.
30. As a player, I want normal level-ups to offer buffs from my weapon's four buff tracks (rank 1–5), so that I can shape its stats.
31. As a player, I want levels 5, 10 and 15 to offer 3 of my weapon's 5 abilities, so that my weapon gains new behaviors at milestones.
32. As a player, I want each card to state exactly what changes ("Zills Lv 3: +1 zill"), so that I can compare options.
33. As a player, I want maxed buff tracks to stop appearing, so that I'm never offered nothing.
34. As a player, I want "Big tip" and "Sip of tea" cards once every buff is maxed, so that late level-ups still help.
35. As a player, I want each weapon to have a weakness-fix ability (Crash Cymbals, Traveling Waves, Silk Storm, Full Spin, Homing Beat), so that any weapon can win a run alone.
36. As a player, I want about 20 level-ups per run, so that I can't max everything and builds differ.
37. As a player using Zills, I want thrown cymbals that gain count, rate, damage and pierce, plus abilities like Ricochet and Boomerang, so that projectile builds feel distinct.
38. As a player using Hip Shimmy, I want a pulsing shockwave aura with daze, plus abilities like Aftershock and Earthquake, so that crowd-control builds feel distinct.
39. As a player using Veil Twirl, I want orbiting veils, plus abilities like Double Helix and Silk Storm, so that defensive orbit builds feel distinct.
40. As a player using the Assaya Cane, I want directional sweeps, plus abilities like Full Spin and Stomp Finale, so that melee builds feel distinct.
41. As a player using Darbuka Drop, I want drum-beat blasts, plus abilities like Homing Beat and On the Beat, so that area-bombardment builds feel distinct.
42. As a player using Darbuka Drop with On the Beat, I want the blasts to land in time with the music, so that the weapon feels musical.

### Admirers
43. As a player, I want Dowry Uncles that are slow, tanky and walk straight at me, so that the opening is readable.
44. As a player, I want Crypto Bros arriving in fast, fragile swarms of 10–20, so that area attacks feel satisfying.
45. As a player, I want Supercar Guys that stop, telegraph for a moment, then charge in a straight line, so that I have to dodge.
46. As a player, I want Influencers that keep their distance and fire a dodgeable selfie flash that slows me, so that ranged pests change how I move.
47. As a player, I want Falconers whose falcon swoops at me and can't be dazzled, so that late-run pressure feels new.
48. As a player, I want admirer types to arrive on a timeline (Uncles and Crypto Bros from 0:00, Supercar Guys at 1:00, Influencers at 2:00, Falconers at 3:00), so that the run escalates.
49. As a player, I want admirers to spawn just off-screen, so that they never pop in on top of me.
50. As a player, I want crowds to spread out instead of stacking into one blob, so that I can read the danger.
51. As a player, I want up to ~300 admirers on screen at a steady 60 fps, so that being mobbed feels huge without lag.
52. As a player, I want the Yacht Sheikh to arrive on a gold-plated jet ski with a big HP bar, so that the boss feels like an event.
53. As a player, I want the Sheikh to use Make It Rain, Entourage, Rose Bouquet and a telegraphed Jet Ski Charge, so that the fight has patterns to learn.
54. As a player, I want admirers to shout short barks ("Ya helwa!", "Wallah I'm serious!"), so that the comedy comes through during play.

### Lamps and passives
55. As a player, I want a lamp to appear off-screen about every 50 seconds, with an arrow at the screen edge pointing to it, so that I have a reason to push through the crowd.
56. As a player, I want walking over a lamp to play a genie-lamp rubbing animation and then reveal a random passive, so that opening one feels magical.
57. As a player, I want a runaway Treasure Camel about twice per run that bolts when I get close and drops a golden lamp (2 passives) when caught, so that chasing it is a fun side goal.
58. As a player, I want passives (Comfy Slippers, Kohl Eyeliner, Big Hair, Oud Perfume, Gold Bangles) to stack up to rank 3, so that repeats still help.
59. As a player, I want lamps to give a cash pile and full Patience once every passive is maxed, so that lamps never feel wasted.
60. As a player, I want passives to affect my one weapon (damage, area, cooldowns) and Shireen (speed, pickup range), so that they combine with my build.

### Pause, display and input
61. As a player, I want Esc to pause with Resume, Restart and Quit, so that I can step away.
62. As a player, I want the game windowed at 1280×720 with F11 toggling fullscreen, so that I can choose how to play.
63. As a player, I want the pixel art scaled by whole numbers with bars filling any leftover space, so that it never looks blurry or stretched.
64. As a player, I want no mouse or controller dependency, so that the keyboard alone is enough.

### Look and sound
65. As a player, I want the game to run silently with placeholder blips until real audio exists, so that missing assets never break it.
66. As a player, I want a chiptune darbuka loop and a separate boss track, so that the mood fits.
67. As a player, I want sound effects for hits, dazzles, pickups, level-ups and UI, so that the action has punch.
68. As a player, I want English text with Arabic flavor words, so that the setting feels authentic without needing Arabic script.

### The user as designer, tuner and artist
69. As the designer, I want every tunable number (weapon stats, buff values, ability values, admirer stats, the spawn timeline, the leveling curve, lamp timing, passive values, boss HP) stored in data files, so that I can rebalance without touching code.
70. As the designer, I want to add a new weapon, ability, admirer or passive by adding a data file and one small behavior class, so that the game can grow without rewriting the core.
71. As the designer, I want the game to reject broken content at startup with a clear message (for example, a weapon missing its weakness fix), so that mistakes surface immediately.
72. As the artist, I want draft sprites generated as editable PNG sheets with documented frame order, so that I can refine them in LibreSprite and see the changes in-game automatically.
73. As the designer, I want the wedding-photo screen to vary by admirer type when art exists, with one shared photo as a fallback, so that art can arrive gradually.
74. As the designer, I want the music BPM in config, so that On the Beat stays in sync when the track changes.

### Bug reporting and collaboration
75. As the user, I want dev builds to save a screenshot every 5 seconds and keep the last 60, so that Claude can see what happened when I describe a problem after the fact.
76. As the user, I want F12 to save a screenshot plus a state dump (run time, Shireen's position and Patience, weapon with its buffs and abilities, passives, admirer count, fps, recent log and errors), so that my reports come with hard data.
77. As the user, I want automatic captures on game over, victory and script errors, so that key moments are always recorded.
78. As the user, I want captures kept out of git, so that the GitHub repo stays clean.
79. As Claude (the developer), I want to run the whole test suite headless from the command line, so that I can verify changes before the user plays.
80. As Claude, I want any run to be reproducible from its seed and inputs, so that a reported bug can be replayed exactly.

## Implementation Decisions

### Architecture: one seam
- **The Run simulation is the single seam.** All gameplay rules live in a headless module of plain GDScript objects (not scene-tree nodes). It's deterministic given a seed, configuration and inputs.
- **Interface:**
  - *Construct* from a run configuration: chosen weapon ID, content set, RNG seed and the play-area extents (640×360).
  - *Advance* with `step(delta, move_direction)` on a fixed timestep of 60 Hz. The view accumulates real frame time and calls `step` as needed.
  - *Choices:* pick a level-up card by index, and continue after a lamp reveal.
  - *Queries:* a read-only state snapshot covering the phase, time, Patience, cash, level and progress, offered cards, Shireen's position and facing, admirers (type, position, state), projectiles and effects, pickups, lamps, the Treasure Camel, boss HP, passives, weapon buffs and abilities, and stats.
  - *Events:* an ordered list emitted per step, including dazzled, cash collected, leveled up, cards offered, lamp spawned and opened, passive gained, boss arrived, overtime started, Patience changed, bark triggered and run ended (with the outcome, plus the last-touching admirer type on a loss).
- **Run phases:** playing, level-up choice (simulation paused), lamp reveal (paused), and ended (victory or defeat). Weapon select and pause happen outside the Run. The view simply stops calling `step`.
- **Determinism rules:**
  - All randomness comes from the Run's own seeded RNG.
  - The Run never reads wall-clock time, engine singletons, input, or the scene tree.
  - The On the Beat beat clock is simulated from the configured BPM. The music view syncs to the Run's beat clock, not the other way round.

### Content plug-in model
- **Content data:** every weapon, buff track, ability, admirer type, passive, the spawn timeline, the boss, the leveling curve, lamp and camel timing, and karkadeh tea live in Godot `Resource` data files.
- **Behaviors:** each weapon, ability, admirer type, passive and boss is driven by a small **behavior** class named by an ID in its data. A content registry maps IDs to behavior classes and data.
- **Adding content:** a new item means a new data file plus a new behavior class. The Run core doesn't change.
- **Ability hooks:** abilities change their weapon through hooks the weapon behavior exposes: stat modifiers, on-fire, on-hit, every-Nth-attack, and periodic triggers. Abilities never reach into weapon internals.
- **Stat model:** a shared stat system with base values, additive and multiplicative modifiers and per-rank values. Buffs, abilities and passives all feed into it, so passives like Kohl Eyeliner and Big Hair work with any weapon.
- **Validation at startup:** the content registry checks that every weapon has exactly 4 buff tracks and 5 abilities, with exactly one weakness fix; that every referenced behavior ID exists; that the spawn timeline only references known admirers; and that numbers are in sensible ranges. Failures stop the game with a readable message.

### Inside the Run
- **Entities as data:** admirers, projectiles, pickups and effects are plain data records (pooled), not nodes. This reverses the earlier "lightweight nodes" idea in the design doc; see the ADR.
- **Spatial grid:** a uniform grid handles separation between admirers and hit queries (circle versus circle, arc, ring). There is no physics engine.
- **Spawn director:** reads the timeline data, spawns admirers in a ring just outside the play area around Shireen, handles swarms (Crypto Bros) and overtime escalation, and schedules the boss at 4:00.
- **Leveling:** the cash curve is `5 + 3·(n−1)` (tunable data). The card generator draws 3 unmaxed buffs, 3 unowned abilities at levels 5, 10 and 15, or the Big tip and Sip of tea fallbacks.
- **Lamp director:** a static lamp about every 50 s, placed off-screen. The Treasure Camel appears about twice per run with flee behavior. Passive rolls are random, either a new passive or +1 rank, with the maxed fallback.
- **Patience:** a per-second drain from each touching, undazzled admirer. Dazzled admirers are excluded at once. The Run records the last-touching admirer type.
- **Boss:** a state machine cycling through Make It Rain, Entourage, Rose Bouquet and Jet Ski Charge, all with telegraphs. Dazzling him ends the run in victory.
- **Barks:** the Run emits bark events (who, which line category). The view picks the audio and text.

### The view (Godot scenes, not tested automatically)
- **Run view:** owns a Run, accumulates time and calls `step`, then draws from the state snapshot. Admirers, pickups and projectiles use a pooled batch renderer (sprite pool or MultiMesh), with frame and flip chosen by state.
- **Screens:** title, weapon select, HUD (Patience bar, level bar, timer, boss HP bar, lamp edge arrow), level-up cards, lamp-rubbing reveal, pause menu, victory screen, "You said yes." screen.
- **Input adapter:** turns keyboard actions into a normalized move vector and menu navigation. Keyboard only.
- **Display:** 640×360 base resolution, `viewport` stretch mode with integer scaling, a 1280×720 window, F11 fullscreen toggle (global), nearest-neighbor filtering.
- **Audio director:** maps Run events to sound effects and barks, plays the music and boss track, and keeps the music in sync with the Run's beat clock. Missing assets fall back to placeholder blips.
- **Debug capture service (global, dev builds only):** rolling screenshots (every 5 s, last 60), F12 snapshot with `state.txt` built from the Run's state snapshot and the log, and auto-captures on run ended and on script errors. Output goes to the gitignored capture folder.
- **Art pipeline:** a generator tool turns code-defined pixel grids into PNG sheets plus a shared palette. Godot reimports edits made in LibreSprite.

## Testing Decisions

- **Framework:** GdUnit4, run headless from the command line, so Claude can run the full suite after every change.
- **What makes a good test:** it goes through the Run seam only. It constructs a Run with a seed and config, feeds inputs (`step`, card picks, continue), and asserts on the state snapshot and the events. Tests never reach into behavior internals, grid layout or private fields. The test reads as a gameplay sentence, for example "a Zills run, standing still for 10 s against 5 Uncles, dazzles at least one and emits cash".
- **Test content:** tests use small, purpose-built content sets (a test weapon or a single admirer type with round numbers) where that makes the intent clearer, and the real content sets to verify the actual game rules.
- **Covered through the seam:**
  - Movement and facing.
  - Patience drain and loss, including the last-touching type.
  - Dazzling and cash drops.
  - Pickup radius.
  - The leveling curve and the card offer rules (buff-only levels, ability levels 5, 10 and 15, maxed exclusion, fallbacks).
  - Each weapon's base behavior, each buff and each ability.
  - Each admirer behavior.
  - The spawn timeline and overtime.
  - Lamps, the camel, passive rolls and maxed fallbacks.
  - The boss patterns and victory.
  - Determinism: the same seed and inputs give the same events.
- **Content validation tests:** the real content set passes registry validation. Deliberately broken content fails with the expected message.
- **Performance smoke test:** a Run with 300 admirers plus pickups stays within a per-step time budget in a headless run. The budget is calibrated once on the user's machine.
- **Not automated:** rendering, animation, the lamp-rubbing animation, audio, menus, display scaling and debug captures. These are checked by playing (F5), with debug captures as evidence.
- **Prior art:** none. This is a new project, and these tests establish the patterns.

## Out of Scope

- Weapon evolutions, extra playable characters, meta progression, save files, unlocks.
- Multiple maps (a wedding hall is a later candidate), blocking props.
- Mouse and controller input, mobile, web and non-Windows builds.
- Arabic script and right-to-left text.
- Rerolls, skips, banishes.
- A balance bot or mass-simulation tool. The seam makes it possible later, but it isn't part of the demo.
- Automated tests of presentation.
- Networking or multiplayer.

## Further Notes

- **Tone rules are part of acceptance** (design doc §1): admirers are archetypes of wealth and status, with no humor about bodies, ethnicity or religion, no religious imagery, and nothing menacing or sexual. Art, barks and screens are checked against these rules.
- **The weapon pools are drafts** pending the user's review (design doc §6). Expect value and ability tweaks before or during milestone 5. The data-driven model makes this cheap.
- **First cut** if time runs short: the Falconer.
- **Build order** (design doc §14) still applies. The work is broken into tickets tracked as [GitHub issues](https://github.com/waleed-khalaf/BampireSurbibors/issues), each titled `NN: <name>`. Tickets 01–08 make up the first playable.
- The user has zero Godot experience. Explanations in the code and commits should say *why*, and the user plays each milestone with F5 before the next begins.
