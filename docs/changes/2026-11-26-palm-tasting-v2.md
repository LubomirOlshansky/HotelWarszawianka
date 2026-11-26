- The livestream tasting at the Palm keeps its first pixel look with twice the pixels and much more detail: bigger people with faces that talk, chew and react, a busier street, a comic close-up for the bite and a full comic panel for the MLASK. A fan walks up for a selfie with Kebabulo, and the photo lands on the review card. The race back to Kemal's starts side by side with a 3-2-1 countdown. The mission is still behind a developer switch.

## Backlog
- fixed: the tasting looked "too pixel" and coarse (F). A smooth cel-shaded version and a hi-res outline-shader version were tried; F called them slop and asked for the first version with more pixels and more detail (20:36), so it is the first version's flat-rect pixel art again, at 432 rows (was 216).
  - The scene is drawn as crisp axis-aligned rects only (no ellipses, rotations, gradients or shaders); `toon_pen.gd` and `pixel_art.gdshader` are retired.
  - The people are ~1.4x bigger, outlined, with eyes, catch-lights, brows, noses, talking and chewing mouths, blinks and a breath, posed per beat and per grade. Kebabulo is redrawn (F 20:38): a forward cap, a short trimmed beard, a beige hoodie and a black puffer vest; he shows three wraps at the hello.
  - The MLASK is a full comic panel (F 20:37, concept 3): gold rays, the giant word, his face rising, insets of Zbyszek and the pigeon, the chat as its own panel.
  - The street has pixel detail: framed windows, cornices, awnings, shop signs, AC boxes, geraniums, a balcony, chimneys, a dish, an aerial, rails, kerb stones, bollards, a bin, a hydrant.
  - The stream's layer (chips, chat, line, scoreboard, card) is the kit's 5x7 pixel font again, on its own 216-row layer; a screen narrower than 16:9 gets bars instead of cropped chips.
- fixed: the race back started with the Porsza already moving. Both cars now line up by the Palm and are held until START.
- added: the FAN and SELFIE beats in `palm_tasting.gd`: the ask, his yes, one flash (soft under calm) and the instant print on the RECENZJA card.
- added: sounds for MLASK, the drumroll and the sting, and the blip voices for Kebabulo, Zbyszek and Kemal, made by `tools/make_ui_sounds.py`.
- found: the kebab stand is still at 216 rows; it could get the same 2x detail pass.
- found: on a weak Android, the scene's frame rate (about 3,000 flat rects drawn a frame, up to ~5,000 under the MLASK's rays) needs a check.

## Roadmap
- added: "First minutes: the Tajny klient's tasting in finer pixel art, the fan's selfie and the race's start line (behind DEV → Tajny klient)"
