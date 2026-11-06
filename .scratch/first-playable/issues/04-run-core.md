# Run simulation core and content registry

Status: ready-for-agent
Blocked by: 01

The seam. Plain GDScript objects, no nodes.
- Construct a Run from config (weapon ID, content set, seed, play-area extents). `step(delta, move_direction)` advances it on a fixed 60 Hz timestep. A read-only state snapshot plus a per-step event list.
- Shireen in the Run: 8-direction movement at the configured speed, facing equal to the last movement direction.
- A content registry loading `Resource` data, mapping behavior IDs to classes, and validating at startup with readable errors.
- A shared stat model (base, additive and multiplicative modifiers) for later buffs and passives.
- Seeded RNG owned by the Run. It never reads time, input or the scene tree.
- Tests: movement and facing; determinism (same seed and inputs give the same snapshot); the registry rejects broken content.
