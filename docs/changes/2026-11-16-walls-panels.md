## Backlog
- found: W4 of the walls look, the panel trial, is built behind `barrier_look` `panels` (classic on main; nothing a tester sees changes): the six light rows (`fence_plain`, `bars_black`, `mesh_panel`, `chain_link`, `rail_street`, `hedge_low`) as instanced 2 m panels in their own `panel.gdshader`, one `Panels` MultiMesh per sector; waits for F's look on the phone (docs/PHONE-CHECK.md 7c)
- found: the Adreno 6xx fallback reaches only the runtime city: a prebuilt city baked `panels` has no typed fences to fall back to (an open question of W4)
- found: the walls doc's "visibility range 400 m" for the panels cannot be a distance from the camera (it sits 500 m back at every play zoom); none is set (an open question of W4)
