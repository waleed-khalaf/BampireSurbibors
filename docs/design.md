# Habibi, Get Closer: Design Doc

Status: agreed in the design grilling of 2026-11-06. Numbers marked *(tune)* are first guesses to be balanced in play.

## 1. Pitch

A silly, original survivors-like for Windows, built in Godot. **Shireen**, an Egyptian belly dancer, is mobbed in the desert near Giza by over-the-top Gulf **admirers** who want to propose to her, hire her for their cousin's wedding and shower her with money. She doesn't want any of it. Her dance moves **dazzle** them, and they wander off heartbroken.

**Title:** *Habibi, Get Closer*. It's Shireen's taunt, and she says it at the start of each run.

### Tone rules (non-negotiable)
- The admirers are **comedic archetypes of wealth and status**: tycoons, supercars, falcons, influencers, crypto, dowries. The joke is their excess.
- **No humor based on bodies, ethnicity as such, or religion.** No religious imagery, and no caricatured facial features.
- **Nobody gets hurt, and nothing is sexual or menacing.** Admirers want to marry her, never harm her.
- Test: a Gulf player should be able to laugh at it too.

### Scope
A **silly demo**, original in the genre. We take the survivors-like mechanics (auto-attacks, swarms, XP, level-up cards, timed runs) but none of Vampire Survivors' own names, characters, weapons, UI or sounds.

## 2. Core loop

1. **Weapon select:** pick 1 of 5 weapons. It's your **only weapon for the whole run**.
2. Move with the keyboard. The weapon fires and aims by itself.
3. Admirers close in. Contact drains **Patience**.
4. A dazzled admirer drops **cash**. Collecting cash fills the level bar.
5. **Level-up:** the game pauses, and you pick 1 of 3 cards that buff the weapon or, at levels 5, 10 and 15, give it a new ability.
6. **Lamps** (chests) appear on the map. Opening one gives a random **passive**.
7. The **Yacht Sheikh** boss arrives at 4:00. Dazzle him to win.

## 3. Run structure

| Item | Rule |
|---|---|
| Length | 5:00. The boss spawns at 4:00. |
| Win | Dazzle the Yacht Sheikh → victory screen: **"Shireen stays single!"** |
| Overtime | If the boss is still up after 5:00, his entourage floods in harder and harder until you win or lose. Runs never just time out. |
| Lose | Patience hits 0 → **"You said yes."** plus a wedding photo of Shireen (miserable) next to the admirer type that touched her last. One photo per type if art time allows, otherwise one shared photo. |
| End screen | Time, admirers dazzled, cash collected, weapon, abilities taken, passives. **Play again** goes straight to weapon select. |
| Meta progression | None. No unlocks, shop or save file. Every run starts fresh. |
| Pause (Esc) | Resume, Restart, Quit. |

## 4. Shireen

| Stat | Base |
|---|---|
| Patience (HP) | 100 *(tune)* |
| Move speed | 90 px/s at 640×360 *(tune)* |
| Cash pickup radius | 24 px *(tune)* |
| Patience regen | None by default |

- Patience drains **per second while an admirer is touching her**. Each type has its own drain rate (see §7).
- **Karkadeh tea** is a rare ground drop (~1% per dazzle *(tune)*) that restores 30 Patience.
- She faces left or right. Her **facing direction** is her last movement direction and aims the Assaya Cane.

## 5. Leveling

- Admirers drop **cash**. Bigger admirers drop bigger bills.
- Cash needed for level *n* → *n+1*: `5 + 3·(n−1)` *(tune)*. The target is **about 20 level-ups in a 5-minute run**.
- Every level-up shows **3 cards for the run's weapon**:
  - **Normal levels:** 3 random **buff** cards from the weapon's four buff tracks (each rank 1–5).
  - **Levels 5, 10 and 15 (ability levels):** 3 random **abilities** from the weapon's pool of five. You pick one. Each run ends with 3 of the 5.
  - **When all buffs are maxed:** the fallback cards are **Big tip** (bonus cash) and **Sip of tea** (restore 30 Patience).
- No rerolls, skips or banishes in the demo.
- Each weapon's pool includes one **weakness fix**: an ability that lets the weapon carry a run alone.

## 6. Weapons (draft pools, for review)

Shireen starts each run with the chosen weapon at level 1. Buff values are per rank.

### 6.1 Zills (finger cymbals): thrown projectiles
Base: throws 1 zill at the nearest admirer every 1.2 s, damage 10, pierce 0.

| Buff track | Per rank |
|---|---|
| Damage | +20% |
| Throw rate | +12% |
| Count | +1 zill at ranks 1, 3 and 5; +15% zill size at ranks 2 and 4 |
| Speed and pierce | +10% speed, +1 pierce |

| Ability | Effect |
|---|---|
| **Crash Cymbals** *(weakness fix: single target)* | Zills burst on impact and hit everyone nearby |
| Ricochet | Zills bounce between up to 3 admirers |
| Boomerang | Zills fly back to Shireen and hit again on the way |
| Ring of Bells | Zills orbit her for 1 s before launching, hitting anyone close |
| Rhythm Section | Every 4th throw is a giant golden zill (×3 damage, ×2 size) |

### 6.2 Hip Shimmy: pulse aura
Base: a shockwave ring every 1.5 s, radius 48 px, damage 8, small knockback.

| Buff track | Per rank |
|---|---|
| Damage | +20% |
| Pulse rate | +12% |
| Radius | +12% |
| Daze | +0.15 s stun on hit |

| Ability | Effect |
|---|---|
| **Traveling Waves** *(weakness fix: no range)* | Each pulse also sends a ring rippling out to the screen edge |
| Aftershock | A second ring follows 0.3 s later |
| Coin Spray | Each pulse flings hip-scarf coins outward as projectiles |
| Hypnotic Hips | Dazed admirers turn and walk away, body-blocking the others |
| Earthquake | Every 5th pulse is a screen-wide ring (low damage, big knockback) |

### 6.3 Veil Twirl: orbiting silk
Base: 2 veils orbit at radius 40 px, damage 6 per touch, one rotation every 2 s.

| Buff track | Per rank |
|---|---|
| Damage | +20% |
| Spin speed | +12% |
| Veils | +1 veil at ranks 1, 3 and 5; +20% veil length at ranks 2 and 4 |
| Orbit radius | +10% |

| Ability | Effect |
|---|---|
| **Silk Storm** *(weakness fix: close range only)* | Every 4 s the veils fly out to the screen edge and come back |
| Static Cling | Admirers hit by a veil are slowed 40% for 1 s |
| Double Helix | A second, counter-rotating ring of veils |
| Ribbon Trail | Veils leave a damaging silk trail for 1 s |
| Grand Unveil | Every 8 s the veils burst outward and knock everyone back |

### 6.4 Raqs al-Assaya Cane: directional sweep
Base: a 100° arc sweep in the facing direction every 1.0 s, reach 44 px, damage 14.

| Buff track | Per rank |
|---|---|
| Damage | +20% |
| Swing rate | +12% |
| Arc width | +20° |
| Reach | +10% |

| Ability | Effect |
|---|---|
| **Full Spin** *(weakness fix: front-only)* | Sweeps become a full 360° spin |
| Double Swing | A backswing behind her follows each swing |
| Cane Toss | Every 3rd swing throws the cane as a boomerang |
| Shepherd's Hook | The sweep pulls admirers inward, bunching them up |
| Stomp Finale | Every 5th swing ends in a ground stomp (area damage and stun) |

### 6.5 Darbuka Drop: drum-beat blasts
Base: every 1.6 s, 1 blast at a random point within 160 px, radius 36 px, damage 20.

| Buff track | Per rank |
|---|---|
| Damage | +20% |
| Beat rate | +12% |
| Drops | +1 blast per beat at ranks 1, 3 and 5; +15% radius at ranks 2 and 4 |
| Blast radius | +12% |

| Ability | Effect |
|---|---|
| **Homing Beat** *(weakness fix: random aim)* | Blasts land on the densest crowd near her |
| Doum-Tek | Alternating beats: a heavy *doum* (big and slow) and a light *tek* (small and fast) |
| Drumroll | Every 8th beat fires 6 rapid blasts |
| Echo | Each blast leaves a ring that hits again 0.5 s later |
| On the Beat | Beats lock to the music tempo, with +25% damage on the downbeat. Needs the music track's BPM (see §10). |

## 7. Admirers

All admirers walk toward Shireen unless noted. When dazzled (HP 0), an admirer plays a swoon (a heart pop), drops cash and wanders off screen. He doesn't block anything while leaving.

| Admirer | HP | Speed | Drain/s | Cash | Behavior | From |
|---|---|---|---|---|---|---|
| **Dowry Uncle** | 30 | 40 | 10 | 2 | Slow and tanky, walks straight at you, carries a briefcase | 0:00 |
| **Crypto Bro** | 6 | 85 | 4 | 1 | Fast and fragile, spawns in swarms of 10–20 | 0:00 |
| **Supercar Guy** | 20 | 260 when charging | 15 | 3 | Stops, lines up (0.8 s telegraph), charges in a straight line | 1:00 |
| **Influencer** | 15 | 50 | 5 | 3 | Keeps ~120 px away. Every 4 s a selfie flash slows Shireen 40% for 1.5 s (dodgeable) | 2:00 |
| **Falconer** | 35 | 35 | 8 | 4 | Keeps ~140 px away. Every 5 s his falcon swoops at her (10 Patience on hit; the falcon can't be dazzled) | 3:00 |

All values *(tune)*. **First cut if we run short: the Falconer.**

### Boss: the Yacht Sheikh (4:00)
Rides a gold-plated jet ski across the sand, with a big HP bar at the top of the screen (~2500 HP *(tune)*). Attack patterns:
- **Make It Rain:** sprays bundles of cash in a fan. They drain Patience on hit and can't be collected.
- **Entourage:** summons waves of Uncles and Crypto Bros.
- **Rose Bouquet:** lobs roses that leave a slowing petal patch.
- **Jet Ski Charge:** a telegraphed straight-line charge like the Supercar Guy's, only bigger.

Dazzling him triggers the victory screen.

## 8. Lamps and passives

Passives come **only** from lamps (the demo's chests), never from level-ups.

| Source | Rule |
|---|---|
| **Lamp** (static) | Spawns off-screen every ~50 s. An arrow at the screen edge points toward it. Walk over it to open: 1 passive. |
| **Treasure Camel** | Appears ~2× per run, wanders, and bolts when Shireen gets close. Hit it a few times or corner it, and it drops a **golden lamp**: 2 passives. |

- **Opening animation:** a **genie lamp being rubbed** (the game pauses briefly), then the passive is revealed.
- The passive is **random**, not chosen: either a new passive at rank 1 or +1 rank on one she has, up to rank 3.
- If all passives are at rank 3: a big cash pile plus a full Patience refill.
- Expect ~6 lamps + 2 camels ≈ 10 passive ranks per run, out of 15 possible.

| Passive | Per rank (max 3) |
|---|---|
| **Comfy Slippers** | +10% move speed |
| **Kohl Eyeliner** | +15% dazzle power (damage) |
| **Big Hair** | +15% attack area |
| **Oud Perfume** | −8% weapon cooldowns |
| **Gold Bangles** | +30% cash pickup range |

## 9. Look

- **Pixel art, 32×32 characters**, one shared palette of 16–32 colors.
- Characters face left or right only, mirrored with `flip_h`. Top-down three-quarter view.
- **Workflow:** Claude generates draft sprites and frames as PNGs with a script. The user refines them in **LibreSprite**. Godot reimports automatically.
- **Base resolution 640×360**, scaled by whole numbers (×2 to 720p, ×3 to 1080p) using the `viewport` stretch mode with integer scaling. Starts windowed at 1280×720, and **F11** toggles fullscreen.
- **Map:** endless repeating sand near Giza with decorative props (palm trees, a tourist bus, a sleeping camel, a broken-down Lada taxi, distant pyramids). **Props don't block movement.**
- **UI:** a Patience bar, a level bar, the run timer, the boss HP bar, and an arrow at the screen edge pointing to the nearest lamp.

## 10. Audio

- **Music:** one **BeepBox** chiptune loop with a darbuka rhythm at a **fixed, known BPM**, plus a separate boss track. The BPM goes in the game's config for the Darbuka *On the Beat* ability.
- **Sound effects:** **jsfxr** for hits, pickups, level-ups and UI.
- **Voice barks:** recorded by the user. Admirers shout **Gulf-flavored Franco-Arabic** ("Ya helwa!", "Wallah I'm serious!", "Marry me, I have 3 camels!"). Shireen's lines are **Egyptian**.
- The game runs silent with placeholder blips until real assets exist.

## 11. Text and language

English UI with Arabic flavor words (Yalla, Habibi, Mashallah, Wallah). Barks are in Franco-Arabic, in Latin letters. **No Arabic script** in the demo, so no right-to-left handling is needed.

## 12. Controls (keyboard only)

| Action | Keys |
|---|---|
| Move | WASD / arrow keys |
| Menus and cards | Arrow keys + Enter |
| Pause | Esc |
| Fullscreen | F11 |
| Bug snapshot (dev builds) | F12 |

Auto-aim targets the nearest admirer, except the Cane, which uses the facing direction. No dash. No mouse.

## 13. Tech

- **Godot 4.7.x, standard (non-.NET) build. GDScript with static types everywhere.**
- **Target:** up to **~300 admirers on screen at 60 fps** plus pickups, on an ordinary laptop.
- **Architecture (see `docs/adr/0001-run-simulation-seam.md`):** all gameplay rules live in a headless, deterministic **Run simulation**, which is also the single test seam (GdUnit4, headless). Godot scenes only draw its state and feed it keyboard input.
  - Admirers, projectiles and pickups are data records inside the Run, drawn by a pooled renderer. They aren't nodes and they don't use physics.
  - Separation and hits use a spatial grid with distance checks.
  - Weapons, abilities, admirers, passives and the boss plug in as data plus a small behavior class, so new content doesn't change the core.
- **Data-driven tuning:** weapon, buff, ability, admirer and spawn-timeline numbers live in `Resource` files (`.tres`), not hard-coded, so balancing is editing data.

### Debug captures (dev builds only)
- **Rolling capture:** a screenshot every 5 s, keeping the last 60 (~5 min).
- **F12 bug snapshot:** a screenshot plus `state.txt`. It records the run time, Shireen's position and Patience, the weapon with its buffs and abilities, her passives, the admirer count, fps and the last log lines and errors.
- **Auto-snapshots** on game over, victory and script errors.
- Saved to `debug_captures/` in the project, named by date and time, and excluded by `.gitignore`.
- When the user reports an issue, Claude reads the matching captures before changing code.

### Workflow
- Claude writes the scripts and scenes. The user plays with **F5** and gives feedback.
- A git repo with one commit per working feature, pushed to GitHub (`waleed-khalaf/BampireSurbibors`).
- Work items live in GitHub Issues (see `docs/agents/issue-tracker.md`). The full demo spec is `docs/demo-spec.md`.

## 14. Build order

| # | Milestone | Playable result |
|---|---|---|
| 1 | Foundation | Shireen walks on endless sand, the camera follows, debug captures work |
| 2 | Admirers arrive | Uncles chase her, Patience drains, game over shows "You said yes." |
| 3 | Core loop | Zills dazzle admirers, cash drops fill the level bar, buff cards appear. **First playable.** |
| 4 | Full run | Weapon select, 5:00 timer, spawn timeline (Crypto Bro, Supercar Guy), boss shell, victory, pause |
| 5 | All weapons | All five weapons with their buffs and abilities |
| 6 | All admirers | Influencer, Falconer, the Yacht Sheikh's patterns |
| 7 | Lamps | Static lamps, Treasure Camel, passives, the lamp-rubbing reveal |
| 8 | Art and audio | Sprite refinement, music, sound effects, barks, wedding photos |

## 15. Out of scope for the demo

Weapon evolutions, extra characters, meta progression and saves, multiple maps (a wedding hall is a candidate for later), mouse and controller input, mobile and web builds, Arabic script, rerolls and banishes, blocking props.
