# All Saints (wszystkich): model log

Spec: `docs/landmarks/specs/wszystkich.md`.

- 2026-11-01: front and towers on the kept LoD2 skin (788 tris), domed towers from memory.
- 2026-11-06: Mac photo report (`photo-reports/wszystkich.md`) listed the gaps: spires not domes,
  arcades, crossing drum, colour, portals.
- 2026-11-26, the Codex pilot (F): whole church replacing LoD2. Refs: Google 3D Tiles (8 orbits,
  4 face views, top) and 6 Street View images, then the spec (Claude, Opus). Built twice from the
  same spec by the Codex CLI in the cloud on F's ChatGPT Plus: GPT-6.2-Sol at high reasoning
  finished in 13.5 min (6,844 tris, mesh and site checks green, 5.36 M input tokens of which
  5.20 M cached, 34 k output); GPT-6.2-Astra at high stopped at 13.7 min when the two runs had used
  the 5-hour limit, its unfinished model already close to Sol's (6,777 tris). Sol's build kept;
  the lane session lightened the copper (#86a898 to #96b8a4) after the reference sheet.
  Codex could not run the turntable inside its sandbox (no X display) and made its own CPU
  previews; the lane session rendered the real turntable.
- Still differs from the references: the tower lantern stages are round where the photos read
  squarer; the front relief and tracery are simplified; the arcades sit a little forward of the
  top view. Not seen yet: the night look and the phone.
