# Zills and dazzling

Status: ready-for-agent
Blocked by: 06

- Run: a weapon behavior framework with ability hooks (stat modifiers, on-fire, on-hit, every-Nth, periodic). Abilities are left empty for now.
- Zills base: 1 zill at the nearest admirer every 1.2 s, damage 10, pierce 0. Projectiles are data records, and hits are checked through the spatial grid.
- Dazzle at 0 HP: the admirer stops draining and blocking at once, swoons, and walks off. Counts toward "admirers dazzled".
- View: zill sprites, the swoon and heart pop.
- Tests: Zills fire at the nearest admirer at the configured rate; damage dazzles at the right HP; pierce limits.
