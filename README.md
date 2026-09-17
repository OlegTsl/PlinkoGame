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
Pin contacts play `assets/sounds/collide.wav`; basket landing plays
`assets/sounds/collect.wav` together with the score animation. Both assets are
48 kHz stereo 16-bit PCM WAV files supported directly by Defold.

Landing awards the configured basket score and persists it between launches.
Debug builds expose a standalone ImGui **Cheats** button in the top-left corner.
It opens controls for adding one or five balls, clearing local progress and
restarting. The cheats UI is automatically absent when using a release engine.
The launcher panel starts below the debug overlay and can be moved. The cheats
window can also be moved and has a close button. The complete interface is
scaled by a private view constant of 2.5.
Press **~** (the backquote/tilde key) in a debug build to toggle the independent
white `@render: draw_debug_text` overlay with persisted per-basket hits, total score and hit
percentages. Statistics are not rendered inside ImGui. A private render/view
constant enlarges the debug text by 2.5 without adding a gameplay config option.
The overlay includes a semi-transparent dark full-screen GUI backdrop beneath
the render text.
The project uses the official Defold Dear ImGui extension 2.14.0.
The audit includes clean Lua syntax/lint checks. The full resource build is
currently blocked by native ImGui diagnostics; desktop/mobile visual review
remains outstanding. See the [audit report](docs/AUDIT.md) for exact scope and limits.

Project documentation:

- [Project structure](docs/PROJECT_STRUCTURE.md): directory boundaries,
  dependency direction and rules for stable Core modules.
- [Audit and refactor report](docs/AUDIT.md): findings, fixes, API checks and deferred work.

- [Project rules](AGENTS.md) and [requirements](TASK.md).
- [Architecture and implementation handoff](docs/ARCHITECTURE.md): modules,
  folder structure, state, persistence, field generation, scaling, and gameplay.
- [Original motion specification](docs/PHYSICS_IMPLEMENTATION_PLAN.md): retained
  design history; its port/DAG algorithm is superseded by the latest request.
- [Current physical motion](docs/PHYSICS.md): implementation and manual review.
- [LevelBuilder](docs/LEVEL_BUILDER.md): generated layout, GUI anchors and visual
  templates.
