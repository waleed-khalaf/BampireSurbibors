# 02: Shireen walks on endless Giza sand

**What to build:** Shireen appears on endless desert sand near Giza and walks in 8 directions with WASD or the arrows. She faces her last movement direction, and the camera follows her.

**Blocked by:** 01 (Project boots)

**Status:** ready-for-agent

**GitHub issue:** #2

- [x] Run: Shireen moves at the speed set in her data, diagonals are normalized, and facing stays on the last non-zero direction.
- [x] The content registry loads Shireen's data from a Resource and validates it, with readable errors.
- [x] A sprite generator tool produces the shared palette, Shireen's sheet (2-frame idle shimmy, 4-frame walk), a seamless sand tile and a few props (palm tree, Lada taxi). The frame order is documented for LibreSprite.
- [x] View: animation by state, sprite flip by facing, a pixel-snapped following camera, endless sand, and decorative props that never block movement.
- [x] Tests: distance moved per second, diagonal speed, facing kept when she stops, and the registry rejecting invalid data.

## Comments

**2026-11-06 (Claude):** Implemented on branch `ticket-02-shireen-walks`. All five criteria met: 15 headless tests pass via `run_tests.cmd` (4 movement/facing tests through the Run, 7 content-registry tests), and a scripted play-through of the real scene confirmed the walk and idle animations, the left/right flip, the pixel-snapped camera, the endless sand and props scrolling past. Broken content stops the game on a screen listing each problem. Draft sprites come from `generate_sprites.cmd`, which never overwrites an existing PNG unless `--force` is passed. Frame order and base points are in `art/README.md`.

**2026-11-06 (Claude):** Review follow-up. Fixed: an unreadable `.tres` now gives a message instead of a crash; `RunConfig` takes the content set as a required argument, so code under `src/run/` never loads files (ADR-0001); the generator exits non-zero on failure. Left open: spec story 17 also lists a tourist bus, a sleeping camel and distant pyramids. This ticket only asked for the palm tree and the Lada, and no later ticket picks up the rest yet. The Run's content check is an `assert`, so release builds rely on the view's check before a Run starts.
