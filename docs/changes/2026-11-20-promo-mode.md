## Backlog
- added: Promo Mode (Settings → DEV → Promo mode, off by default), F's tool for framing the trailer and Reels on the phone: a +15 / -15 minute clock button on the game screen, the clock's speed (pause to 600x), a CAR camera with its own angle, tilt and view, a FREE camera that flies over the city with the finger (and eased glides and spins for video moves), the frame readout (world and GPS coordinates, yaw, tilt, view height, game time, date, sun), 16:9 / 9:16 / 4:5 / 1:1 guides, a thirds grid, the HUD invisible or hidden, saved shots and COPY (the game flags that render the same frame on the Mac)
- found: a real portrait rotation on the phone needs portrait in the app's Info.plist (the export writes landscape only, and iOS stops an app that turns to an orientation its plist lacks); Promo Mode shows a 9:16 guide instead, and the final vertical clips render at 1080x1920 on the Mac from COPY's flags
- found: the camera is orthographic (the post pass reads its depth as one), so there is no field of view to change; the view's height in metres is the zoom

## Roadmap
- added: "Promo tools for the trailer (Promo Mode)" (ticked)
