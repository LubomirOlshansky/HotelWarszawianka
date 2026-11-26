- The livestream tasting at the Palm is now finer pixel art, with almost twice the pixels, ink outlines and more detail on the street, and faces that react, talk and chew. A fan walks up for a selfie with Kebabulo, and the photo lands on the review card. The race back to Kemal's starts side by side with a 3-2-1 countdown. The mission is still behind a developer switch.

## Backlog
- fixed: the tasting looked "too pixel" and coarse (F). A smooth version was tried and F asked for pixel art with more pixels, so it is now pixel art at ~360-400 rows (was 216).
  - The new `toon_pen.gd` draws cel-shaded shapes into a nearest-filtered pixel viewport (the screen divided by a whole number), and the new `pixel_art.gdshader` adds one-pixel ink outlines and bands the gradients.
  - The people are shaded fake-3D figures with eyes, brows and mouths, posed per beat and per grade.
  - The street has pixel-model detail: window crosses, AC boxes, geranium boxes, balconies, shop signs, roof kit, granite kerbs, bollards, a bin, a hydrant.
  - The stream's overlay (chips, chat, bubble, card) stays sharp, in the system font.
- fixed: the race back started with the Porsza already moving. Both cars now line up by the Palm and are held until START.
- added: the FAN and SELFIE beats in `palm_tasting.gd`: the ask, his yes, one flash (soft under calm) and the instant print on the RECENZJA card.
- added: sounds for MLASK, the drumroll and the sting, and the blip voices for Kebabulo, Zbyszek and Kemal, made by `tools/make_ui_sounds.py`.
- found: the kebab stand still has the old 216-row pixel look. It should get the same pen and finish next.
- found: on a weak Android, the scene's frame rate with the full-screen post pass needs a check.

## Roadmap
- added: "First minutes: the Tajny klient's tasting in finer pixel art, the fan's selfie and the race's start line (behind DEV → Tajny klient)"
