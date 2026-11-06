# First playable (milestones 1–3)

Status: ready-for-agent

A slice of `.scratch/demo/spec.md`. It's the smallest build that answers "is this fun?": Shireen walks on endless Giza sand, Dowry Uncles swarm her, Zills dazzle them, cash drops lead to buff cards, and losing all Patience ends on "You said yes."

It's built on the Run-simulation seam (`docs/adr/0001-run-simulation-seam.md`). Rules go in the Run, tested headless with GdUnit4. Scenes are the view.

## Done when
- The user presses F5 and plays a run that ends in "You said yes.".
- Debug captures appear in `debug_captures/`.
- The GdUnit4 suite passes headless.
