# Admirer base and Dowry Uncle spawning

Status: ready-for-agent
Blocked by: 04

- Admirer data in a `Resource` (`data/admirers/dowry_uncle.tres`): HP 30, speed 40, drain 10/s, cash 2.
- Admirers are lightweight nodes moved by code toward Shireen, with simple separation so crowds don't stack. No physics bodies. Built to reach ~300 at 60 fps.
- A spawner places Uncles just off-screen at a rate that ramps over time.
- Performance check: a debug key or flag that spawns 300 admirers, with the fps shown in the F12 state.
