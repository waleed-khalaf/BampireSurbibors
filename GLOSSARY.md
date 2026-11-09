# Glossary

Domain terms for *Habibi, Get Closer*. Use these words in code, issues and docs. The `Avoid` column lists synonyms to steer clear of. Full design is in `docs/design.md`.

| Term | Meaning | Avoid |
|---|---|---|
| **Shireen** | The player character, an Egyptian belly dancer. | player sprite, hero |
| **Admirer** | Any enemy. A Gulf suitor who wants to marry, hire or tip Shireen. Types: Dowry Uncle, Crypto Bro, Supercar Guy, Influencer, Falconer. | enemy (in UI and docs; `Enemy` is fine as an internal base-class name only if needed), mob |
| **Boss** / **Yacht Sheikh** | The end-of-run admirer who arrives at 4:00. | |
| **Dazzle** | What happens when an admirer's HP reaches 0: he swoons, drops cash and leaves. *Dazzle power* = damage. | kill, die, death |
| **Patience** | Shireen's health. Drained per second by touching admirers. | HP (for Shireen), health, lives |
| **Drain** | Patience lost per second while an admirer touches Shireen. | contact damage |
| **Touching** | An admirer whose body circle is against Shireen's (within a pixel). Only touching admirers drain Patience. The **last-touching** type is the admirer type that took the last of her Patience; she appears next to him in the wedding photo. | colliding, hitting |
| **Cash** | XP pickups dropped by dazzled admirers. Fills the level bar. | XP gems, exp |
| **Level-up** | A pause showing 3 cards for the run's weapon. | |
| **Weapon** | One of 5 dance moves: Zills, Hip Shimmy, Veil Twirl, Assaya Cane, Darbuka Drop. Chosen at the start; exactly one per run. | attack, skill |
| **Buff** | A level-up card that adds a rank (1–5) to one of the weapon's four stat tracks. | upgrade (too vague) |
| **Ability** | A level-up card offered at levels 5, 10 and 15 that adds a new behavior to the weapon. Each weapon has 5; a run takes 3. | evolution, perk |
| **Weakness fix** | The ability in each weapon's pool that lets it carry a run alone. | |
| **Lamp** | The demo's chest: a brass genie lamp in the sand. Opening it gives 1 random passive. | chest (in UI and docs) |
| **Golden lamp** | A better lamp dropped by the Treasure Camel. Gives 2 passives. | |
| **Treasure Camel** | A runaway camel (~2 per run) that drops a golden lamp when caught. | |
| **Passive** | A stat item from a lamp, rank 1–3: Comfy Slippers, Kohl Eyeliner, Big Hair, Oud Perfume, Gold Bangles. | item, relic |
| **Karkadeh tea** | A rare ground pickup that restores Patience. | health potion |
| **Prop** | Decorative scenery on the sand: palm trees, a Lada taxi and so on. Exists only in the view, so it never blocks Shireen. | obstacle, scenery object |
| **Facing** | The direction Shireen last moved in (one of 8 with the keyboard). It stays the same while she stands still and aims the Assaya Cane. Her sprite only mirrors left or right. | heading, orientation |
| **Run** | One 5-minute attempt, from weapon select to the end screen. | level, stage, round |
| **Run simulation** | The headless, deterministic module that holds every gameplay rule for a run. Advanced with `step`, read through its state snapshot and events. The project's single test seam (ADR-0001). | game manager, world |
| **Behavior** | The small class that gives a weapon, ability, admirer, passive or the boss its logic, picked by ID from its data file. | script, controller |
| **Content registry** | Loads and validates all content data and maps behavior IDs to classes. | database, manager |
| **View** | The Godot scenes that draw the Run simulation and feed it input. They hold no rules. | client, frontend |
| **Overtime** | After 5:00 with the boss still up: the entourage floods in until the run ends. | |
| **Bark** | A short shouted voice line from an admirer or Shireen. | |
| **Debug capture** | A dev-build screenshot (rolling every 5 s, F12 or automatic) plus an optional `state.txt`, saved to `debug_captures/`. | |
