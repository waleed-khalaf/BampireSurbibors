# ADR-0001: Gameplay rules live in a headless Run simulation

Status: accepted (2026-11-06)

## Context

*Habibi, Get Closer* is a survivors-like with up to ~300 admirers on screen, five weapons with 25 abilities, five passives and a spawn timeline. The user wants to expand it later (more content, possibly saves, other platforms). Godot's default style puts logic inside scene nodes, with one node and script per enemy. That's easy to start with, but it's slow with large swarms, can't be tested headless or deterministically, and tangles rules with presentation as content grows.

## Decision

- All gameplay rules live in one **Run simulation**: plain GDScript objects, deterministic given a seed, config and inputs, advanced on a fixed 60 Hz timestep. It never touches the scene tree, input, wall-clock time or engine singletons.
- The Run is the project's **single test seam**. Tests construct a Run, feed inputs (step with a move direction, card choice, continue) and assert on its state snapshot and events. The test framework is GdUnit4, run headless.
- **Admirers, projectiles, pickups and effects are data records inside the Run**, drawn by a pooled batch renderer in the view. This replaces the design doc's original "lightweight nodes moved by code".
- **Content plugs in:** each weapon, ability, admirer, passive and the boss is a `Resource` data file plus a small behavior class picked by ID through a content registry. The registry validates the content at startup. Adding content doesn't change the Run core.
- **Godot scenes are the view:** menus, HUD, camera, effects, audio and animations. They read the Run's state and feed it input. They aren't tested automatically.

## Consequences

- **Good:** fast headless tests; reproducible bugs (seed plus inputs); performance headroom for big swarms; cheap content additions; saves, replays, a balance bot and other platforms become feasible later.
- **Bad:** more structure upfront than a node-only design; admirers can't be inspected in the editor's scene tree mid-run (debug captures and the `state.txt` dump make up for it); the code looks less like typical Godot tutorials.
- **Guardrail:** no entity-component framework, plugin system or networking preparation. Keep just the boundary.
