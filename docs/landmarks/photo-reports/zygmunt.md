# Kolumna Zygmunta (Sigismund's Column, Plac Zamkowy) reference report
Files: refs/zygmunt/ (3 photos: 1 the column and its steps from the square, 2 column with the Castle, 3 close-up against the sky; ortho.jpg 120 m square).
Ortho frame (north up): **x = -784.2 + px*0.0586, z = -1525.4 + py*0.0586** (2048 px file). Gathered 2026-11-06 on F's Mac; licences in SOURCES.md; positions ±1.5 m. No spec exists yet; the model is `_build_zygmunt` (landmarks.gd).

## What the photos show
- **Position**: the column's foot is at **x -724.3, z -1466.4** in the ortho (code: -724.2, -1465.4), so the code's spot is right to 1 m.
- **Shaft**: one grey-brown granite monolith (#9a9186, polished, slightly darker at the base), the longest part, about **55-60 % of the whole 22 m height**; it has a **bronze base ring** with sculpted eagles/coats of arms at its foot and a **bronze Corinthian capital** (dark, about 1.6 m tall).
  Above the capital a **square abacus block** (grey stone, steps outwards), then the king.
- **Pedestal**: a dark grey granite block on a darker base: about **4 m tall, square, base chamfered**, bronze inscription plaques on each face (two seen on the front face in photo 1, tall rectangles).
  The spec's pale-stone die (#d2c4ad) is wrong; it is **grey granite #77746f**, with the bronze plaques the only colour.
- **King**: dark bronze (#3b3a36), cloaked, in armour, a **tall cross held up beside the head (on the viewer's left in photo 1)** and a drawn **sabre lowered on the other side**. About 2.75 m; the cross reaches about 4.5 m over the abacus.
- **Steps**: the column stands on a **polygonal stepped platform**: 3-4 broad low steps of grey granite (each about 0.15 m high, 0.4 m tread; photo 1 shows them as
  long flat steps, with people sitting on them), spreading about 7-8 m from the pedestal, the front arc wider. The ortho shows a stepped polygon at the foot (about 6 m across)
  and **concentric arc lines on the south-west side about 12 m out** (wide paving steps, the plaza's lower terrace edge).
- **Plaza**: light grey granite setts with **brick-pink bands** running from the Castle side across the square (width 1.2 m), a cobbled field; plenty of pedestrians.
  The Castle wall is **orange-red plaster with white-framed windows and red-tile roofs; the clock tower has a green copper bulb roof**.
- Colour palette: shaft #9a9186, pedestal #77746f, steps #a39e96, bronze #3b3a36, capital #4a443a.

## Gaps against the current model
1. Pedestal die uses pale stone (#d2c4ad); the photos show **dark grey granite**. The shaft is also the same pale stone; should be grey-brown granite.
2. The bronze base ring/eagles at the shaft's foot and the bronze Corinthian capital are missing (plain boxes).
3. Steps: 3 octagonal steps of r 3.4..2.2 m; photos show **4 broad low steps and an outer arc** (about 7 m out).
4. Cross/sabre sides: photo 1 shows the cross on the viewer's left of the head and the sabre low on the other side (check the model's facing in game).
5. The bronze plaques on the pedestal faces are missing.

## Sources (photos stay on F's Mac in refs/zygmunt/, gitignored)
- 1.jpg: https://commons.wikimedia.org/wiki/File:Kolumna_Zygmunta_Warszawa_2018.jpg, Zala, CC BY-SA 4.0
- 2.jpg: https://commons.wikimedia.org/wiki/File:Warszawa,Kolumna_Zygmunta,_Zamek_Kr%C3%B3lewski.jpg, Aw58, CC BY 3.0
- 3.jpg: https://commons.wikimedia.org/wiki/File:Kolumna_Zygmunta,_Warszawa.jpg, Chichebombon, CC BY-SA 4.0
- ortho.jpg: GUGiK orthophoto, 2048 px, ~120 m, fetched 2026-10-31, open data.
