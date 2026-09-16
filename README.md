# PlinkoGame

Defold project for a configurable Plinko mini-game. Open `game.project` in the
Defold editor and run the `main` collection. Press **Play** to drop one ball or
**x5** to queue five balls. The selected basket is logged below the score and
in the console. A request may wait while its physical trajectory is prepared.
Play consumes one available ball and x5 consumes five. The inventory panel is
always visible. The timer panel shows `+1 in hh:mm:ss` below maximum and `Ready`
at full capacity; real-time regeneration continues between launches.

Motion uses gravity and continuous circle/wall collisions, with a small
background-generated route bank. Bounces follow contact normals, including
repeat pin hits and side-wall rebounds. See [current physics](docs/PHYSICS.md)
for the algorithm, configuration and the change from the original DAG plan.

Landing awards the configured basket score and persists it between launches.
The latest physics changes
have not been built, run or tested, as requested; visual review is required.

Project documentation:

- [Project rules](AGENTS.md) and [requirements](TASK.md).
- [Architecture and implementation handoff](docs/ARCHITECTURE.md): modules,
  folder structure, state, persistence, field generation, scaling, and gameplay.
- [Original motion specification](docs/PHYSICS_IMPLEMENTATION_PLAN.md): retained
  design history; its port/DAG algorithm is superseded by the latest request.
- [Current physical motion](docs/PHYSICS.md): implementation and manual review.
- [LevelBuilder](docs/LEVEL_BUILDER.md): generated layout, GUI anchors and visual
  templates.
