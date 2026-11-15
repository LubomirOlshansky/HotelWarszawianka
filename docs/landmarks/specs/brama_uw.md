# Brama Główna Uniwersytetu (the University's main gate): spec

**Superseded 2026-11-15** by `uw_kampus.md` section 2 (rebuilt from F's own photos of the gate).

Site key `brama_uw` in `game/scripts/landmarks.gd` (`_build_brama_uw`). Written 2026-11-02 in a cloud thread from the Mac's reference set `refs/krakowskie/` (29 Wikimedia Commons photos, three GUGiK orthophotos at 0.137 m/px; report `docs/landmarks/photo-reports/krakowskie.md`, authors and licences there) plus the GUGiK LoD2 heights from the CI map pack. It replaces the 2026-11-01 first pass, which had the OpenStreetMap outline only. Report section 2, photos 5-11.

## 1. Identity

Stefan Szyller's main gate of the University of Warsaw (1910), Krakowskie Przedmieście 26/28, facing the street (WSW): two white pavilions with statues in niches (Minerva, Apollo), curved gables with cartouches, lanterns and finials; the black wrought-iron gate with a crowned eagle between them; a narrow iron side gate and an urn pier outside each. The lime avenue behind it leads to Pałac Kazimierzowski (`kazimierzowski.md`).

## 2. Massing

Frame: origin (-462, -642) on the east building line (ortho, ±4 m; the first pass guessed (-494.5, -684)), u south along the street (0.37, 0.93), +v out to the street. The clear opening between the pavilions is the University's own figure, 3.8 m wide by 4.5 m high (F, 2026-11-03, bgl.uw.edu.pl/obiekty), so the pavilions (4.4 x 4.4 m) stand at u ±4.1; 7 m to the cornice, gable steps to 10 m, lantern to 12.8 m, finial to 14 m. Side gates 3 m (u ±6.3..9.3); piers at u ±9.8 with urns to 5.1 m. 20.6 m in all (the first pass's 6 m opening made it 22 m; the mapped gap is ~19 m). The mapped 4.3 m "guardhouse" at (-465, -646) (the north pavilion) is replaced.

## 3. Facade, base to top

Plinth, white body with corner pilasters on the street face, a round-headed niche with a standing statue, cornice, two stepped gable blocks with a cartouche disc, octagonal lantern, cone cap, gilt finial. Gate: two rails, six bars, an overthrow at 4.5 m (the opening's height), the eagle (body and wings) with a gilt crown to 5.95 m.

## 4. Roof

No roof: the gable steps and lanterns crown the pavilions.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Pavilions, piers | #f2f0ea | M_STONE |
| Mouldings, plinth, urns | #dcd6c8 | M_STONE |
| Niches | #dcd6c8 darkened | M_STONE |
| Iron | #25282a | M_STONE |
| Finials, crown | #c9a24a | M_STONE |

## 6. Ground and night

The campus road, the avenue's limes and the street lamps are the map's. The car meets a wall across the gate (20.4 x 2.3 m). Card "Brama Główna Uniwersytetu".

## 7. Detail level and budget

L2, triangle budget 950 (built 826).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| pavilions | boxes | 4.4 x 4.4 x 7 m | u ±4.1 | M_STONE #f2f0ea | white pavilions |
| gables | 3 stepped boxes, disc | to 10 m | pavilion tops | M_STONE | curved gable, cartouche |
| lanterns | prism, cone, finial | to 14 m | pavilion tops | M_STONE | lantern |
| niches, statues | arch panel, figure | 1.6 x 3.8 m, 2.6 m | street faces | M_STONE | Minerva, Apollo |
| main gate | rails, bars, eagle | 3.8 x 4.5 m clear | centre | M_STONE #25282a | crowned eagle |
| side gates | rails, bars | 3.2 x 2.9 m | u ±7.8 | M_STONE | iron gates |
| piers | box, urn | 1 x 1 x 3.9 m | u ±9.8 | M_STONE | urns |
