# Art

Draft sprites for *Habibi, Get Closer*, drawn by code and meant to be refined by hand in **LibreSprite** (ticket 26). Godot reimports a PNG as soon as you save it, so your edits show up the next time you press F5.

## Making the drafts

```
.\generate_sprites.cmd
```

This draws every sheet that doesn't exist yet. It never touches a file that's already there, so your edits are safe. `.\generate_sprites.cmd --force` redraws everything from scratch and **overwrites your edits**. The drawings are code in `tools/sprite_generator/generate_sprites.gd`.

## Palette

All sprites share one palette of 27 colours.

- `palette.gpl`: load it in LibreSprite with **Palette > Load Palette** before editing, so you paint with the same colours.
- `palette.png`: the same colours, one pixel each, in the same order.

If you add a colour, add it to `PALETTE` in the generator too, so new drafts can use it.

## Sheets

All characters face **right**. The game mirrors them to face left, so don't draw a left-facing copy. Keep transparent backgrounds and the same canvas size, or the frames won't line up in the game.

### `shireen/shireen.png`: Shireen, 192×32

One row of six 32×32 frames, left to right:

| Frame | x | Animation | Notes |
|---|---|---|---|
| 0 | 0 | Idle | Hips swayed left |
| 1 | 32 | Idle | Hips swayed right |
| 2 | 64 | Walk | Left foot forward |
| 3 | 96 | Walk | Passing, body up 1 px |
| 4 | 128 | Walk | Right foot forward |
| 5 | 160 | Walk | Passing, body up 1 px |

Idle plays at 3 frames per second and walk at 8 (`src/view/shireen_sprite.gd`). Her feet touch the sand at **(16, 30)** in every frame. That point is where the game places her, so keep her feet there.

### `admirers/dowry_uncle.png`: Dowry Uncle, 64×32

One row of two 32×32 frames, a walk cycle that plays at 4 frames per second (`src/view/admirer_renderer.gd`):

| Frame | x | Notes |
|---|---|---|
| 0 | 0 | Left foot forward |
| 1 | 32 | Right foot forward, body up 1 px |

His feet touch the sand at **(16, 30)**, like Shireen's.

Every admirer sheet has this same layout: two 32×32 walk frames, feet at (16, 30). New sheets go in `admirers/`, named after the admirer's id: the `id` field inside his `.tres` file in `content/admirers/`, so `dowry_uncle` → `art/admirers/dowry_uncle.png`. The game finds them by that name, so nothing in the code needs to change. If a type's sheet is missing, the game warns in the Output panel with the path it expected and draws nothing for that type.

### `world/sand.png`: sand tile, 64×64

Repeats forever in every direction, so anything that runs off one edge has to continue on the opposite edge. LibreSprite's **View > Tiled Mode** shows the repeats while you paint.

### `props/`: decorative props

Props never block Shireen. The base point is where the prop stands on the sand, and the game uses it to decide what's in front of what.

| File | Size | Base point |
|---|---|---|
| `palm_tree.png` | 32×48 | (16, 46) |
| `lada_taxi.png` | 48×32 | (24, 29) |

If you move a base point, update `PROPS` in `src/view/prop_scatter.gd` to match.
