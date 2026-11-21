## Backlog
- added: Promo Mode's VERTICAL / HORIZONTAL button (F 2026-11-20: "for vertical reels all the interface ... can change to horizontal or vertical"): the screen turns to portrait and back, the promo panel moves to the bottom, the guide takes 9:16, the view keeps its scale as the screen turns, and PROMO OFF turns the screen back to landscape
- added: `tools/export_ios.sh --portrait`, the iPhone build that may turn (its Info.plist lists portrait, the export carries the `promo_portrait` feature); without the flag the button is hidden on the iPhone and the players' builds stay landscape only, launch screen included
- fixed: a portrait screen would have drawn a much coarser image (the image scale is measured on the screen's height): main.gd `_apply_style` now measures the short side, so portrait keeps the landscape image's sharpness and pixel count

## Roadmap
- ticks nothing new ("Promo tools for the trailer (Promo Mode)" is ticked)
