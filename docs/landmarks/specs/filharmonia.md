# Filharmonia Narodowa: spec

Site key `filharmonia` in `game/scripts/landmarks.gd` (`_build_filharmonia`, `_fil_composer`).
Written 2026-11-02 in a cloud thread from the Mac's reference set (`refs/filharmonia/`, 3 Wikimedia
Commons photos and a GUGiK orthophoto; report `docs/landmarks/photo-reports/filharmonia.md`), the
OpenStreetMap outline and GUGiK LoD2. The mass stays LoD2's in a skin; the model is the Jasna front.

## 1. Identity

The National Philharmonic on Jasna (Karol Kozłowski, 1901; rebuilt 1955).

1. **A giant order of smooth cream-white Ionic columns** along the Jasna front, over a balcony.
2. **A rusticated arcade of round-headed openings** on the ground floor, one per bay.
3. **FILHARMONIA NARODOWA cut in the frieze**, a balustrade on the attic.
4. **Two composers** on the balcony (Chopin and Moniuszko), not one per bay.
5. **The corner's neon**: the round "fn" sign on a bracket out of the Sienkiewicza wall (a red ring
   round green letters) and SALA KONCERTOWA (the institution's own name).

Reworked 2026-11-24 from more Commons photos (`refs/filharmonia/4.jpg`-`14.jpg`, sources in its
SOURCES.md): the first model had tall arched windows to 13 m, ten composers and small ground-floor
windows that sat behind the base and never showed.

## 2. Massing

Frame: origin (-860.7, -77.7), the mapped front's north end; u along it to (-837.6, -27.0) (55.7 m),
+v out of it to Jasna (east). Corner bays 4.8 m solid at both ends, eleven columns between them
(bay 4.6 m).

| Part | Where (u, v) | Heights over the ground |
| --- | --- | --- |
| Face | 0..55.7, -0.25..0.35 | 4.5 to 15.0 m |
| Base | -0.2..55.9, -0.25..0.75 | -0.6 to 4.5 m |
| Columns | u 4.8 + k 4.6, v 1.55, r 0.62 | 4.5 to 15.0 m |
| Entablature, cornice | v -0.55..2.6 | 15.0 to 16.65 m |
| Attic | v -0.25..0.45 | 16.65 to 18.0 m |

## 3. Facade, base to top

The rusticated base: a step, a round-headed opening per bay (2.7 m wide, its spring at 2.75 m, dark
behind an iron transom) and the piers between them banded with grooves every 0.6 m. The balcony on
the base's cornice (v 0.15-2.45) with an iron railing between the columns; in each bay a rectangular
French door (1.7 x 3.45 m, brown frame with a cross) and its lintel, the wall plain above. Two
standing composers in white stone (2.6 m) on the balcony either side of the middle. The Ionic
columns (volutes either side of the capital); the entablature with FILHARMONIA NARODOWA in dark
stone letters (0.62 m), the cornice, and the attic's balustrade (plinth, balusters every 0.62 m,
posts every 4.6 m, the rail).

## 4. Roof

LoD2's roof shapes in the skin's lead grey (#8e9392); the raised hall roof in the middle stays LoD2's.

## 5. Colour and material

Walls #e3ded2 (the report), columns #ede9de, base #c9c3b5, statues #f1efe9, windows #232a33,
iron #2b2c2e, lead #a2a7a8, neon green (0.2, 1.0, 0.45). M_STONE, M_GLASS; the skin M_MONUMENT.
The neon words FN, SALA and KONCERTOWA (two rows: as one the hall's name is wider than the atlas) join neon_signs.gd's LANDMARK_WORDS.

## 6. Ground and night

On the terrain at the front's ends; the base's line is the car's. At night the fn roundel's red ring
and green letters (both faces, on its bracket 1.5 m out of the Sienkiewicza wall, 3 m back from the
corner) and the hall's name glow; the windows take the city's glow.

## 7. Detail level and budget

L2, 1196 triangles, budget 1450 (check_mesh_quality). Shot: `--at=-838,-55 --yaw=75 --size=35
--pitch=-58`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| skin | LoD2 mass | the outline | Jasna 5 | M_MONUMENT #e3ded2 / #8e9392 | colour |
| face | box | 55.7 x 0.6 m, 10.5 m | the front | M_STONE #e3ded2 | facade |
| base | box | 56.1 x 1.0 m, 5.1 m | the front | M_STONE #c9c3b5 | facade base |
| columns | 11 columns | r 0.62 m, 10.5 m | v 1.55 | M_STONE #ede9de | 1 the colonnade |
| arcade | 10 arches | 2.7 m wide, to 4.1 m | the base, one per bay | M_GLASS #232a33 | 2 the arcade |
| grooves | 6 rows | 0.04 m | the piers and end bays | M_STONE base darkened | 2 the arcade |
| balcony | box | 56.1 x 2.3 m | the base's cornice | M_STONE #e3ded2 | 1 the colonnade |
| doors | 10 French doors | 1.7 x 3.45 m | between the columns | M_STONE #5e3a26 | facade |
| railings | 10 boxes | 0.95 m | the balcony's edge | M_STONE #2b2c2e | 1 the colonnade |
| composers | 2 figures | 2.6 m | the balcony, either side of the middle | M_STONE #f1efe9 | 4 composers |
| capitals | volutes | 1.9 x 1.0 m | the column tops | M_STONE #ede9de | 1 the colonnade |
| inscription | letter runs | 0.62 m high | the frieze | M_STONE #5f5a50 | 3 the inscription |
| balustrade | plinth, balusters, posts, rail | 1.3 m | the attic | M_STONE #e3ded2 | 3 the attic |
| entablature | 2 boxes | 56.1 x 3.2 m, 1.65 m | over the columns | M_STONE #ede9de | 1 the colonnade |
| roundel | 2 discs on a bracket | r 1.05 m, ring M_LAMP #ff4a2a | the Sienkiewicza wall | M_STONE #232a33 | 5 the neon |
| neon | 3 words | FN (both faces), SALA / KONCERTOWA | the corner | neon sign | 5 the neon |
