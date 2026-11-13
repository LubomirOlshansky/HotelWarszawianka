## Backlog
- fixed: before/after test shots always used the car's follow camera (the car in the picture, the view following it); `--cam=X,Z` or `--cam=X,Y,Z` is a free camera for tests and screenshots (hidden from players): fixed on a world point, turned by `--yaw=`/`--pitch=`, `--size=` tall, car hidden (`--cam-car` keeps it), on the runtime and the prebuilt city (verify step `freecam`; documented in the screenshot-review skill and the flags table)
- found: the free camera is orthographic like the game's; an eye-level perspective camera is not built (nothing asked for it yet)

## Roadmap
- added: "Free camera for before/after test shots (F, 2026-11-13)": ticked, `--cam=X,Z` in main.gd with `follow_camera.gd` `parse_free` / `free_view`, check `check_free_cam`
