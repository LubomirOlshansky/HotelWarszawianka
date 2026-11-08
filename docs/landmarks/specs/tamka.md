# Tamka from F's photos: spec

Not one site: a street pass (`game/scripts/tamka.gd`, the house looks read by `map_builder.gd`'s
Dobra/Tamka dress through `TenementTrim`). Written 2026-11-08 from F's photo gather on the Mac
(`warsaw-needed-photos/powisle`: C-Tamka 1-01..1-10, houses/tamka-10-12, -16, -20, -34, -36, M01-M04,
I-STOR; sources in its SOURCES.md, Wikimedia Commons and fotopolska.eu). Photos are reference only,
never in the repo. Plan item P13 / the first Tamka pass of `docs/powisle-plan.md`.

## 1. Identity (what the photos say Tamka is)

1. **Post-war blocks, not pre-war pastels**: five to ten storeys of cream, sand and pale-yellow
   plaster with columns of balconies on dark steel rails; a few 1990s fronts (Tamka 16's glass bay
   towers over a red-brick ground floor); the ornate white pre-war tenements only by Kopernika (45-49).
2. **Black bollards** every couple of metres along both kerbs, the whole length of the street.
3. **The footbridge** from the Ostrogski castle's terrace over Tamka to the bank on the south side,
   a concrete deck on square piers with light steel railings and a 3.9 m sign.
4. **Huge ad wraps and murals on the blank firewalls** by the footbridge (a film poster, a portrait),
   and the poet's mural at the Kopernika end (not built yet: item T-murals below).
5. **Shops on every ground floor**: a bistro, a bank, a butcher's, a filter-coffee café (STORCZYK
   in the game at Tamka 33), café umbrellas on the pavement.

## 2. The houses (tamka.gd HOUSES; the rest of Tamka in PASTELS)

| House | Look | Style |
| --- | --- | --- |
| Tamka 10/12 | cream #e4dbbd, five storeys | attic: a row of small dark square openings, no cornice |
| Tamka 16 | cream #dcd0b6 | red-brick ground floor #a5503a |
| Tamka 20 | cream-yellow #e3d5a6, ten storeys | balconies, grey-green rails |
| Tamka 34 | cream with salmon #ddc8b4, the rounded corner | balconies, black rails |
| Tamka 34A | brown-salmon #b98466 | balconies, black rails |
| Tamka 45, 45A, 45B | ornate white #e8e2d6-#ece7de | iron balconies |
| Tamka 47 | white #e4ddcf | shops |
| other homes on Tamka (8 m or taller, within 26 m) | PASTELS (cream, sand, pale yellow, warm grey, salmon-cream) | half with balconies (dark rails) |

Balconies (TenementTrim `_balconies`): on a street wall, a column every second 3.6 m bay, from 3.4 m
up a storey (2.9 m) at a time to 2.2 m under the top; a slab 2.3 x 0.95 m and a 1.0 m rail; 12
triangles each, in the walls' own tile meshes (no draw call).

## 3. Street

- Bollards: black posts 0.9 m with a cap, 2.1 m apart, 0.45 m behind both kerbs of every Tamka
  carriageway 6 m wide or more; none across a side street's mouth, a zebra or under the footbridge.
- Footbridge: the mapped footway's ends (-17, -285) to (-31, -328); the deck's underside 4.3 m over
  the road under its middle, 0.7 m deep, 3 m wide; cut where the ground climbs to it; piers 7.5 m
  either side of the crossing where the ground is low; railings with posts every 1.6 m; steps down
  at an end that stays over the ground. A collider for the deck and piers.

## 4. KEBONAFIDE (F's ask, 2026-11-08)

A parody rap star who lives on Tamka (own name, own lines, no lyrics): platinum hair, round dark
glasses, a few face-tattoo marks, an oversized black hoodie with a pink K, a gold chain, wide
trousers, white trainers; his dalmatian Plamka on a red lead. He walks the north pavement from
Tamka 36 to Tamka 18 and back (155 m) 09:00-22:30, the dog stopping to sniff every 38 m; a slow car
within 16 m gets a line (the `car` lines and the rest, 22 s apart), the street gets one every
35-60 s while the view is within 70 m (`kebonafide` in data/dialogue.json: retiring every year,
farewell tours, Burrito Hemingway, Ciechanów, matcha prices, KEBAB FM). One mesh (480 triangles),
+1 draw call near him, none elsewhere. Add-ons: Beehave / Dialogue Manager not used (one walker on
a fixed path and single lines).

## 5. Left (next Tamka passes)

- T-murals: the firewall ad wraps and murals by the footbridge and at Kopernika (parody posters).
- The Ostrogski castle rebuilt from the photos (M01-M04): a white palace with a central risalit and
  pediment on the high red-brick bastion, the balustraded terrace and the double stairs to Okólnik;
  the current model's round turret is not in any photo.
- Tamka 16's glass bay towers; the Kopernika end's planters and the stairs up the bank.
- More houses by address as photos come (HOUSE-COVERAGE.md on the Mac lists 27 matched of H001-H300).
