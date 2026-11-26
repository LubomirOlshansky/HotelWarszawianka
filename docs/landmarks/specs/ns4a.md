# Nowy Świat 4A (OSM "Nowy Świat 2.0") and Muzeum Narodowe's roof sign: spec

Site key `ns4a` in `game/scripts/landmarks/srodmiescie.gd` (`_find_ns4a`, `_build_ns4a`); the
museum's sign is `_muzeum_sign` in `game/scripts/landmarks/plac.gd`, its letters `_serif_word` in
`common.gd`. Written 2026-11-26 from F's two night photos from Rondo de Gaulle'a, Google Street
View (2026-08) and the Google 3D Tiles renders. References are never committed or shipped.

## 1. Identity

A glass office corner on Nowy Świat just south of Dom Partii: a 78 m wedge along the lane, its west
end rounded onto the street. What makes it: four glass floors with dark frame bands and vertical
fins that glow at night, the white-and-red band under a set-back glass top storey, and the Polish
flag on a tall pole over the round end. Tenant sign as a parody: PGR (for PGZ; "pgz" is on the
brand denylist). The ground floor is PRZEGRYWKI, the board-game and arcade bar (Zagrywki parody,
F's "zGrywki"; storefronts.gd venue `bar_przegrywki` at this corner).

The museum's sign: a stylised zigzag wave (not the real mark) and MUZEUM NARODOWE in white serif
capitals on the west wing's roof, facing the rondo (the institution's own name).

## 2. Massing

From the mapped parts: the outline (ground floor), the overhang from 6.6 m (OSM min_height), parts
to 20.8 m and 24.1 m. Lobby 0-6.6 m (outline 1 m in), fascia 6.6-7.4 m (0.5 m out), glass storeys
7.4-20.8 m (0.3 m out), band and terrace 20.8-22.3 m (0.6 m out), top storey 22.3-24.6 m (1.6 m in).

## 3. Facade

Four storeys of 3.55 m: silvery glass, a dark frame band at each floor (0.6 m proud), fins every
1.6 m (0.3 m wide, 0.42 m proud). Lobby: glass behind round columns every 9 m. The top storey is
plain glass behind a 1 m glass rail.

## 4. Roof

Flat grey roof with a white parapet; a white plant box (10 x 5.2 x 3.2 m) 16 m from the round end;
an 11 m white pole 6.5 m from the round end with the flag (2.7 x 1.7 m, white over red, fixed in a
waving shape).

## 5. Colour and material

Glass #b4c6ca (M_PAVILION + 0.5: lit cool white floor to ceiling at night, as the photo), frame
bands #2a2c30, fins #d3dadd (M_LAMP: glow at night), copper fascia #8a4a2f, lobby glass #3f3a62
(M_PAVILION + 0.375: pink-violet at night), band red #d4213d and white #f1f1ee, top glass #5d7277.
Museum sign letters #f4f6f8 (M_LAMP), steel #2c2e31.

## 6. Ground and night

The car collides with the lobby ring (the overhang is 6.6 m up). At night: the four glass floors
glow white, the fins whiter, the lobby pink-violet, the PGR sign lit (landmark signs are lit day
and night). The museum's letters glow white.

## 7. Detail level and budget

L1 for ns4a, budget 1200 triangles (measured 1097). The museum's sign adds about 1,250 to the
`muzeum` site (budget 4600, measured 4478). No new draw calls: both are in the city's building
surface; PGR is one instance in the landmark-sign MultiMesh.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| lobby | prism on outline 1 m in | 0-6.6 m | ground floor | M_PAVILION + 0.375 | PRZEGRYWKI's lit lobby |
| columns | 8-sided prisms r 0.32 | 6.6 m | every 9 m, 0.3 m in | stone | the lobby's columns |
| fascia | prism 0.5 m out + soffit | 6.6-7.4 m | over the lobby | stone, copper | the copper band |
| glass | prism 0.3 m out | 7.4-20.8 m | four storeys | M_PAVILION + 0.5 | lit floors |
| bands | rings 0.6 m out | 0.47 m tall | each floor line | stone, dark | frame bands |
| fins | quads 0.3 m | 13.4 m tall | every 1.6 m, 0.42 m out | M_LAMP | glowing fins |
| flag band | ring + deck 0.6 m out | 20.8-22.3 m | over the glass | stone, red and white | the flag colours |
| top | prism 1.6 m in | 22.3-24.6 m | set back | M_GLASS | glass top storey |
| box | box | 10 x 5.2 x 3.2 m | 16 m from the round end | stone, white | roof box |
| flag | pole + six strips | 11 m, 2.7 x 1.7 m | 6.5 m from the round end | stone | the Polish flag |
| pgr | landmark sign | k 0.42 | band's north face by the corner | neon atlas | parody tenant sign |
| museum_sign | beams | cap 1.65 m, ~34 m | west wing roof, 1.4 m in | M_LAMP, steel | wave + MUZEUM NARODOWE |

## Open

A night look on the phone (the fins' and letters' glow), the flag's size at phone scale.
