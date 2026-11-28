## Backlog
- fixed: Google 3D Tiles reference renders stopped (HTTP 403, Google's EEA terms for EEA-billed projects); tools/tiles3d/render.mjs now loads the same tiles through Cesium ion when CESIUM_ION_TOKEN is set
- found: #1162, #1164 and #1166 blamed "the daily cap" for missing 3D Tiles; it was this 403. Their "check when the cap allows" items (Pałac Prymasowski annexes, Hotel Saski bays, Politechnika courtyards) can be checked now
