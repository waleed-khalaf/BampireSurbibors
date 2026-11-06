# Zills and dazzling

Status: ready-for-agent
Blocked by: 05

- A weapon framework: one weapon node per run, configured by a `Resource` (base stats plus four buff tracks plus an ability list, with abilities empty for now).
- Zills base: throws 1 zill at the nearest admirer every 1.2 s, damage 10, pierce 0.
- Hit detection by distance (spatial grid if needed), not physics.
- Dazzle: at 0 HP the admirer plays a swoon and heart pop, stops draining, walks off screen and frees itself. Counts toward "admirers dazzled".
