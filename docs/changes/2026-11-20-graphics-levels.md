- The graphics levels are rebuilt around what really costs frames, the picture's resolution: Ultra now draws the sharp 2x picture on every phone with smoother edges (MSAA) and soft shadows, and the iPhone 11 runs it at a steady 60 fps (it was about 42).
- Experimental is now called Max and is open to everyone: every graphics extra at the sharp 2x picture.
- A new Picture setting, Obraz Piksel / Pełny (Image Pixel / Full): Full draws the screen's own pixels on any level, the sharpest picture for screenshots.
- Low graphics run at a steady 30 fps.

## Backlog
- fixed: the levels from the per-option costs (F's go 2026-11-20): Low `cap` 30 (main.gd _apply_fps, the player's choice can only lower it); Ultra keeps High's 0.96 MP budget (x2 on every phone; x1 on the iPhone 11 was 41.8 fps) plus MSAA 4x and soft shadows (SOFT_LOW); Experimental → Max (`--quality=max`, Settings "Maks · Max", shown to everyone, x2 at the same budget, every extra); Settings → Obraz "Piksel / Pełny" (settings.gd image_full, tiers.gd full_image) for the screen's own pixels on any level; shots that used Experimental's x1 now pass `--gfx=full=true`
- found: bench route on this branch. iPhone 11: Ultra 60.0 (1% low 43.9), High 60.0 (48.8), Max 51.4 (38.3). Samsung A56: High 58.6, Ultra 44.2 (MSAA 4x costs the Xclipse 540 about 3 fps against 47.7 without), Max 27.9, Low 83.4. Nothing Phone 1: Auto (Low) 29.3 / 35.5 uncapped (a steady 30 with the cap), Medium 27.9. iPhone 16 Pro Max (2026-11-19, the same settings by --gfx=): Ultra + MSAA 4x 60.0, Max at x2 60.0 / 59.9
- found: OWED: the iPhone 16 Pro Max bench of the new Ultra, Max and Max + Full in normal power mode (the 2026-11-21 rerun was invalid: the phone reported 60 Hz, Low Power Mode; Ultra read 41.4); PHONE-CHECK 15zm
- found: the Jarmark thread's `--trailer` (Experimental, governor off, `--lines=1920`) keeps the full image with these levels: `lines_override` sets the image's scale directly, so Max's x2 budget doesn't apply to it
- found: Ultra's MSAA on Android may want 2x (the Samsung's 3 fps); Max on Android phones is a manual heavy choice (28 fps on the A56)
