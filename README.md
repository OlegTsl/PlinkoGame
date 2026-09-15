# PlinkoGame
Defold Plinko game
# PlinkoGame

Defold project for a configurable Plinko mini-game. Open `game.project` in the
Defold editor and run the `main` collection. The current runnable slice builds
the static level (spawn point, pin pyramid and score baskets) from GUI-authored
anchors and the configured basket list.

Project documentation:

- [Project rules](AGENTS.md) and [requirements](TASK.md).
- [Architecture and implementation handoff](docs/ARCHITECTURE.md): modules,
  folder structure, state, persistence, field generation, scaling, and gameplay.
- [Dedicated motion specification](docs/PHYSICS_IMPLEMENTATION_PLAN.md): the
  later replacement for the baseline trajectory and animation placeholders.
- [LevelBuilder](docs/LEVEL_BUILDER.md): generated layout, GUI anchors and visual
  templates.
