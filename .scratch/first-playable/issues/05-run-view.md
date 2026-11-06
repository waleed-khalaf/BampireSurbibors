# Run view: Shireen, camera, endless sand

Status: ready-for-agent
Blocked by: 03, 04

- A Run view scene that owns a Run, accumulates frame time into fixed steps and calls `step` with input from the keyboard adapter.
- Draws Shireen from the snapshot (animation and flip by facing), a pixel-snapped following camera, endless tiled sand with scattered decorative props.
- Registers the Run snapshot with the debug capture service.
- Verify by playing.
