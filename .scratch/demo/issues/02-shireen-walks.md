# 02: Shireen walks on endless Giza sand

**What to build:** Shireen appears on endless desert sand near Giza and walks in 8 directions with WASD or the arrows. She faces her last movement direction, and the camera follows her.

**Blocked by:** 01 (Project boots)

**Status:** ready-for-agent

- [ ] Run: Shireen moves at the speed set in her data, diagonals are normalized, and facing stays on the last non-zero direction.
- [ ] The content registry loads Shireen's data from a Resource and validates it, with readable errors.
- [ ] A sprite generator tool produces the shared palette, Shireen's sheet (2-frame idle shimmy, 4-frame walk), a seamless sand tile and a few props (palm tree, Lada taxi). The frame order is documented for LibreSprite.
- [ ] View: animation by state, sprite flip by facing, a pixel-snapped following camera, endless sand, and decorative props that never block movement.
- [ ] Tests: distance moved per second, diagonal speed, facing kept when she stops, and the registry rejecting invalid data.
