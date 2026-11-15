# Kampus Centralny Uniwersytetu Warszawskiego (the University's main campus): spec

Written 2026-11-15 from F's 21 photos of that day (`refs/uw_campus/f_photos`, IMG_8047 to IMG_8074,
reference only, never shipped), the campus board in front of the gate (its numbered plan 1-23 and
its aerial, photos 8051-8054), the OSM outlines and GUGiK's LoD2 heights from the CI map pack.
It replaces the gate of 2026-11-02 (`brama_uw.md`, built from Commons photos) and adds the rest of
the campus. Code: `game/scripts/landmarks/old_town.gd`, section "The University's main campus";
the skins in `game/scripts/landmarks/fronts.gd` SKINS.

## 1. The board's numbers against the map

The board draws the campus with Krakowskie Przedmieście at the bottom and Powiśle at the top, so
its "up" is the game's east (+x). OSM names most buildings by the faculty inside.

| Board | Name | OSM outline | Site | What the game draws |
| --- | --- | --- | --- | --- |
| 1 | Brama Główna | (none: the gate's own frame) | `brama_uw` | model, rebuilt |
| 2 | Szpital św. Rocha | Instytut Kultury Polskiej UW | `uw_roch` | LoD2 in white plaster, grey roof |
| 3 | Pałac Czetwertyńskich-Uruskich | Wydział Geografii i Studiów Regionalnych UW | `uruski` | LoD2 mass in cream, street front modelled; LoD2 merges it with the Tyszkiewicz palace and its annex into one model centred outside Uruski's outline, so the skin's `run` point catches it and all three are cream |
| 4 | Szkoła Języków Obcych | Centrum Nauczania Języków Obcych UW | `uw_jezyki` | LoD2 in grey-white |
| 5 | Gmach Pomuzealny | Wydział Historii UW | `uw_pomuzealny` | LoD2 in pale stone |
| 7 | Szkoła Główna | Wydział Archeologii UW | `uw_szkola_glowna` | LoD2 in yellow, red roof |
| 8 | Gmach Porektorski | Wydział Kultur Azji i Afryki | `uw_porektorski` | LoD2 in cream, red roof |
| 12 | Pawilon Mineralogiczny | Wydział Polonistyki UW | `uw_mineralogiczny` | LoD2 in cream, red roof |
| 13 | Pałac Kazimierzowski | Pałac Kazimierzowski | `kazimierzowski` | LoD2 in yellow; west portico (2026-11-02) and the garden front over Powiśle modelled |
| 15 | Auditorium Maximum | Auditorium Maximum | `auditorium_maximum` | LoD2 in pale render |
| 16 | Gmach Poseminaryjny (Collegium Iuridicum I) | Wydział Prawa i Administracji UW | `uw_poseminaryjny` | LoD2 in white, red roof |
| 17 | Stara Biblioteka | Stary BUW | `stara_buw` | LoD2 mass in pale stone under green copper; front and flanks modelled |
| 18 | Gmach Audytoryjny | Wydział Nauk Politycznych i Studiów Międzynarodowych | `uw_audytoryjny` | LoD2 in pale stone |
| - | the guards' kiosk | kiosk "Ruch" (green, red roof) | `uw_straz` | model |
| - | the escarpment wall | wall line, first point (-210.5, -650.9) | `uw_skarpa` | model (OSM's wall left out) |
| - | bollards, chains, flagpoles | (none) | `uw_kampus` | model, no card |

6, 9, 10, 11, 14 and 19-23 keep the map's default look for now (no photo of them).

## 2. The gate (`brama_uw`), photos 8047-8049

Frame as before: origin (-462, -642), u south along the street, +v out to the street; opening
3.8 x 4.5 m. Each pavilion (4.4 m square): plinth to 0.9 m, body to 5.9 m with two pairs of banded
pilasters (six grooves each) and garland capitals; a shell-headed niche with a statue on a console;
entablature to 6.75 m; a segmental pediment (rise 1.1 m) on the street and campus faces round a
cartouche; a stepped attic with two scrolls, a thin grey cap at 9.5 m, a pedestal, and an iron lamp
post to 13.45 m with a lit lantern (the 2026-11-02 model had a stone lantern and a gilt finial: the
photos show an iron lamp). Three flags on brackets on the south pavilion (Poland, Warsaw, the EU).
Main gate: three rails, thirteen bars, a ring of scrolls in each leaf, an arch of scroll bars rising
1.35 m, the eagle with raised wings and a gilt crown. Side gates: frame, bars every 0.32 m, a
scrolled overthrow, a ring in the middle. Outer piers: banded shaft to 5.1 m, cornice, carved urn
to 7.5 m.

## 3. Pałac Uruskich's street front (`uruski`), photos 8047, 8049

Frame: from (-487.3, -691.7) to (-469.2, -650.5), +v out to the street. End risalits u 0-11.3 and
33.8-45.0 stand 0.6 m out; the middle u 11.3-33.8. Rusticated ground floor to 5 m, a ledge. Middle:
seven bays, ground windows, first-floor windows with pediments (the second bay a balcony door with
an iron balcony over the street door), second-floor windows, cornice at 16 m, a statue on a
pedestal over the middle. Risalits: three bays, a storey taller (windows at 1.3, 6.4, 11.0 and
15.4 m), corner pilasters, a row of consoles under the deep cornice at 20.6 m (LoD2: 21 m).

## 4. The Old Library (`stara_buw`), photos 8050, 8056, 8070, 8071

Frame: the west face from (-334.9, -713.7) to (-324.3, -690.5), +v west down the avenue. The middle
(u 6.1-19.4) stands 2.9 m out (the outline). Rusticated ground floor to 4.6 m: in the middle a niche
with a statue, the arched door, a niche with a statue. Four Corinthian half-columns from 5 to 15.4 m
with three round-headed windows (sill 6.4 m) over little balustrades, and the mezzanine's paired
windows at 12.7 m; the ends with pilasters, one arched window each and a balustrade on the cornice.
Entablature 15.4-16.7 m; on the middle the attic to 20.1 m with a working clock (the game's
`_dial`: hands at Warsaw time, lit at night) and the group of three statues on a plinth to about
23 m (LoD2: 24.4 m). Flanks (the first 24 m of each long side): giant pilasters every ~4.6 m,
ground and arched windows, a bust on a console between each pair. Roof: LoD2's, green copper.

## 5. Pałac Kazimierzowski's garden front, photos 8065-8068

The middle risalit's face over the escarpment, from (-238.7, -736.0) to (-244.1, -747.6), +v east:
yellow wall with white corner pilasters; three tall French windows; an iron balcony across the
first floor's three round-headed windows; three square windows on the second floor; cornice at
13.2 m; a segmental gable rising 3 m with an oculus and a pair of statues. In the garden 9 m out the
old howitzer on a stone plinth.

## 6. The escarpment wall (`uw_skarpa`), photos 8066-8068

OSM's 298 m wall line round the campus's east and north edge (the drop to Powiśle and the BUW).
Per segment: the lower side is the slope's; the wall runs from under the slope's ground up to a
metre over the campus, 0.6 m thick, red brick (#9a4a36) with a darker course every 1.5 m on the
slope face and a concrete coping; a brick pier every 6 m; graffiti pieces every 5-14 m where the
face is over 1.8 m tall (magenta, teal, white, black, yellow, violet: affectionate tags, no
words); the iron railing on the coping along the palace's terraces (the first 17 points). The
footpath under the wall is the map's. OSM's 2 m grey wall is left out (`city_barriers.gd`
SITE_WALLS).

## 7. The guards' kiosk (`uw_straz`), photos 8063, 8074

On OSM's kiosk outline: a dark green plinth, green panelled walls to 3.1 m with pilasters and wide
windows with pale blinds, a glazed door on the longest side with a pale name board over it, a
deep green cornice, a red hipped roof to 4.25 m with three green vent boxes.

## 8. Furniture (`uw_kampus`)

Cast-iron bollards every 2.9 m, 3.2 m in front of Pałac Uruskich, with sagging chains (8049). Five
flagpoles 11 m tall 13 m in front of the Old Library, two left and three right (8056).

## 9. Ground and budget

Benches, lamps, trees and paths stay the map's (OSM has the campus's trees and benches). Budgets
(check_mesh_quality.gd): brama_uw 4000, uruski 4000, stara_buw 5000, kazimierzowski 2200, uw_skarpa
7000, uw_straz 900, uw_kampus 1500. Draw calls: none added (all in the city mesh).

## 10. Defaults (no photo)

The pavilions' campus faces copy the street faces' pediment but have no niche; the Old Library's
east end and the Uruski court side stay LoD2's; the Uruski statue is placed over the middle's
centre (the photo shows it over the middle's north part).
