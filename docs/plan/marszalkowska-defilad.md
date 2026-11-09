# Marszałkowska by the art museum: as rebuilt, without artefacts

Plan for F's ask of 2026-11-08 (phone shots IMG_7622-7624, FullSizeRender): Marszałkowska along Plac
Defilad, from the Sienkiewicza–Fangora crossing to the Złota crossing (past Muzeum Sztuki
Nowoczesnej), has buggy turnarounds and broken lanes on the west carriageway. Remove the
turnarounds and rebuild the stretch as it is after the 2025-26 "Zielona Marszałkowska" rebuild.

Street coordinates below are `s` (metres south along the tram midline from the Świętokrzyska
junction centre, map point -1055.7, -134.3, towards -885.3, 328.5) and offsets (metres, + west, the
museum side; - east, the Wiecha / Uniqlo side). Same axis as `m_south` in `docs/roads/palace.json`.

## 1. What is wrong in the game today

The map draws every OpenStreetMap way of the street as its own ribbon (main as base, F 2026-11-07).
OSM (data of 2026-10-27) already has the rebuilt street, but in pieces that our bake turns into
artefacts here:

| s (m) | OSM way | What the game draws |
| --- | --- | --- |
| 155-170 | Fangora's exit (1123326779) joins the west carriageway mid-ribbon | a kerb wedge at the mouth |
| 188-205 | `secondary_link` 1409581461, **access=no**, from Sienkiewicza across the tram to the west carriageway | an opening cut through the tram median, a lane graph edge nobody may drive |
| 233-286 | west carriageway way 1416765104 with **3 lanes** (`turn:lanes=reverse\|none\|none`: a U-turn pocket) between 2-lane ways | the carriageway widens and narrows, lane lines jog and bend (F's red circle) |
| 286 | `secondary_link` 1409581465, the **zawrotka** (U-turn) south to north just before Złota | a second opening through the tram median with U-turn arrows |
| 160-330 | east carriageway ribbons 2/3 lanes | inner kerb ~1.4 m too close to the tram (-4.5 instead of -5.9), no green strip |

The ground under all this is right; the street just has no single cross-section.

## 2. How it is in real life (research)

Sources: ZDM "Zielona Marszałkowska – rusza przebudowa" (June 2025), PropertyDesign (5 June 2025),
TVN Warszawa (track works), Super Express (6 Oct 2025, trams back 13 Oct 2025), Murator /
Super Express (3 Aug 2026, Złota and the Sienkiewicza–Fangora crossing opened), the city's
"Zielona Marszałkowska – organizacja ruchu i zieleń po przebudowie" plans (Biuro Infrastruktury)
and ZDM renders F sent (um.warszawa.pl, noizz.pl), the OSM ways of 2026-10, the GUGiK orthophoto
(spring 2025, before the rebuild: used only for what did not change).

- **Two lanes each way**, extra turning lanes only at junctions ("dwa pasy ruchu na każdy kierunek,
  z dodatkowymi pasami do skrętu na skrzyżowaniach", ZDM).
- **Trees between the tram and the cars**: a row of narrow columnar elms ('Columella', fiorente)
  with a low cotoneaster hedge on each side of the track ("tramwaje od samochodów oddzieli szpaler
  drzew"). On this stretch the track itself is paved and drivable for ambulances (green sedum track
  only north of Świętokrzyska).
- **Two new at-grade crossings with cycle crossings**: on the Złota axis to Plac Centralny (opened
  November 2025) and Sienkiewicza–Fangora (opened 3 August 2026), about 130 m apart. Both are
  already in the game; keep them.
- **A zawrotka near Złota** and a **left turn at Sienkiewicza** are in the ZDM plan. OSM has the
  zawrotka (1409581465); its Sienkiewicza link is tagged access=no.
- **Parking along the museum**: OSM `parking:right=separate` on s 205-286 and five little paths
  from the kerb through the museum's beds (s 213, 229, 245, 261, 276); the ZDM render shows bays
  there. East side: bus stop (platform at s 236-263) on the pavement.
- OSM crossings give the real cross-section (s 180 and s 310): west carriageway +6.0..+12.5,
  green strip +3.0..+6.0, track -3.3..+3.0, green strip -5.9..-3.3, east carriageway -12.4..-5.9
  (2 x ~3.25 m lanes each way).

## 3. Proposal

Rebuild the stretch with the road design system (`tools/road_design.py`, the way Krucza was done):
one spec, `docs/roads/marsz_defilad.json`, s 170 (just past Fangora's exit) to 328, applied to `centrum.json` and kept by
every re-bake (`apply_all`). Kerbs come from one cross-section, so nothing jogs.

1. **No turnarounds** (F's ask): no opening through the tram median between the crossings; the
   two `secondary_link`s and their graph edges go. The U-turn pocket lane goes with them.
2. **West carriageway** (southbound): +5.8..+12.3 as main has it (within 0.2 m of OSM), two lanes,
   straight-on arrows before Złota. **Parking lay-by** along the museum, s 205-285, out to +15.0
   with short rounded tapers, cars parked in it (`park_cars`).
3. **East carriageway** (northbound): outer kerb as main (-13.7), inner kerb moves out to -5.9 so
   the green strip appears; two lanes. Short tapers back to main's kerbs at both ends of the area,
   away from the crossings.
4. **Tram median**: paved track, a raised grass strip with a **row of young columnar elms** each
   side (about every 9 m, kept clear of the crossings and the refuges), like the ZDM render.
5. **Side roads kept**: Sienkiewicza (east, s ~188) opens the outer kerb only; Fangora's exit
   (west, s ~157, with its island) stays as main has it, just north of the area.
6. **Crossings kept** at s ~175-181 and s ~300-310 with their cycle crossings, refuges on the
   green strips.

Not in this change: the Świętokrzyska junction (built with the metro, not part of the rebuild),
the stretch south of Złota to Rondo Dmowskiego (its own item if F wants it), hedges as separate
models.

## 4. Checks (definition of done: full, it is map geometry)

- `road_design.py marsz_defilad --check`: 0 problems; continuity 0 (paths meet crossings).
- Flat plots before/after, with the lane graph: no lane crosses the tram between the crossings.
- Game shots at F's view, day and dusk, runtime and `--prebuilt`; lane drive both ways.
- `check_map_data.py` counts recorded on purpose (trees, carriage chunks); verify; bench.

## 5. Question parked for F

The real street has the zawrotka by Złota (and the Sienkiewicza left turn is planned). This
change removes them as asked. If F wants the real zawrotka back, it comes back as one clean,
square median gap with its own arrows (one spec line), not as an OSM link.
