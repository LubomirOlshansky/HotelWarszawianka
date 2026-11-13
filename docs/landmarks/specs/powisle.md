# Warszawa Powiśle (site `powisle`)

**Round pavilion rebuilt from F's four photos, 2026-11-06** (day, summer café, dusk event, night
event): the saucer's thin white knife edge (0.35 m) and its underside curving up from the drum to
the rim; on top, 16 radial seams from a round drain in the middle out to the rim (F's 1960s archive photo); WARSZAWA POWIŚLE in fifteen separate dark teal-black letter boxes (1.05 x 1.75 m) on a
steel rail along the rim's front arc, yellow tube letters on stand-offs (yellow by day, lit at
night, a neon glyph over each for the glow); a festoon of warm bulbs all round the rim's lower edge
and three more out to posts over the deck chairs; a dark transom band round the glass drum. The
terrace: thirteen orange deck chairs with a white band (a parody brewery's chairs in the game: the
real ones carry a real beer brand, never drawn), six red-framed café tables with white folding
chairs, and the jazz evenings' stage (section 9). Section 4's lower pavilion and section 8's rows
for it are replaced by this.

## 9. The jazz evenings (F, 2026-11-06)

`landmarks.gd powisle_jazz_plan()` is the one plan the model and `crowds.gd` share. The stage sits
under the canopy's east edge (13 m from the middle, 3 x 7.2 m, 0.6 m high), facing the open paving
towards Kruczkowskiego: the side the game's camera sees past the saucer (south of it the Poniatowski
viaduct hides the ground). Black riser with a cream valance reading JAZZ (a pink JAZZ neon at night),
a truss with warm and blue lamps, two speakers, an upright piano, a double bass, a drum kit and a
vibraphone. Crowds (`powisle_jazz`): the band of four (bass and vibraphone standing, piano and
drums sitting) from 18:30 to 23:30 every evening, sitters in the deck chairs and up to 48 standing
in a fan in front; half full on weeknights, full on Friday and Saturday, thinner out of season and
in rain. The café's tables (`powisle_cafe`) fill from noon. Sound: `jazz_trio` (tools/make_sfx.py,
original synthesis: a swung tune in F at 132 BPM, walking bass, ride and brushes, piano comping,
vibraphone) from the stage while the band is on it, through `city_sounds.gd` (`jazz`, reach 95 m).

Written 2026-11-01 for F's railway ask (docs/design/railway.md, S2). No reference photos in the
cloud; measured from the OpenStreetMap outlines in `centrum.json` ("Dworzec PKP Powiśle", a
24 x 20 m outline at (171, 89) over the tunnel's east mouth; the round roof outline of r 10.6 m
at (401, -6) with a r 8 m building under it; the two side platforms between them) and the facts
from published descriptions (whitemad.pl, archiweb.cz on the lower pavilion's 2013 refit,
Wikipedia). The Mac photo check (`refs/powisle/`) is open: the arches, the saucer's profile,
the canopies' length and the neon's letters.

## 1. Identity

Two little 1960s pavilions at either end of a station on an embankment: the upper one a glass
hall under a white twisted roof (a hyperbolic paraboloid with straight edges: two corners up, two
down, the low one by the bridge's gate tower), at the Aleje level by the Poniatowski Bridge, right over the cross-city
tunnel's mouth; the lower one a round glass drum under a white saucer with its rim turned up
(the "UFO"), the café-club "Warszawa Powiśle" with the station's name in yellow tube letters on top of the rim.
Romanowicz and Szymaniak, designed 1954-55, opened 1963.

## 2. Massing

- Upper pavilion: the OSM outline's frame (about 24 x 20 m), floor at the Aleje level (the
  highest ground under it), a 6 m plinth down the escarpment's falling side.
- Its glass hall set back 1.6 m under the roof's edges.
- Lower pavilion: a glass drum r 7.8 m, 3.4 m tall, at the street level by Kruczkowskiego.
- Platforms: the map's two side platforms on the embankment; a canopy 72 m long over the
  middle of each.

## 3. Facade, base to top

- Upper: glass (M_PAVILION, lit warm at night) up to the roof's underside in 1.8 m panels with
  dark mullions; the tops follow the roof.
- Lower: glass drum with dark mullions every 2 m.
- Canopies: X-shaped steel supports every 7.2 m (two dark beams crossing in the platform's
  cross-section), a thin white slab on top.

## 4. Roof

- Upper (rebuilt from street photos 2026-11-13, F: "the pavilion with the slanted roof"): a 10 x 10
  grid over a hyperbolic paraboloid, 5.2 m over the floor in the middle, its corners 1.8 m up or
  down (3.4-7.0 m), the south-east one low; the edges stay straight. A dark brick-brown fascia
  (0.4 m) runs round the edges. The base down the
  escarpment is glass with mullions, and the blue WARSZAWA POWIŚLE letters hang over the doors on
  the side the game's camera sees.
- Lower: an inverted dome, a shallow saucer of r 14.6 m (it overhangs the drum about twice, per
  the photos): rim 4.5 m over the floor, the middle 0.8 m lower, a 0.45 m rim face, a grey
  underside sloping up from the drum to the rim. No tree grows under it (`tree_free`).

## 5. Colour and material

White #e6e4dd (roofs, arches, canopy slabs), grey #8d9095 (undersides, plinth), dark #2f3236
(mullions, X supports, fascia), glass #5d717c, neon yellow (the round pavilion) and blue (the upper one). Everything in the city's one building surface
(M_STONE, M_PAVILION) plus one neon word (`neon_signs.gd` LANDMARK_WORDS): no new draw calls
beyond the sign's.

## 6. Ground and night

The embankment, the rails, the platforms and the tunnel's mouth are the map's own (portals are
item L3). At night both halls glow warm, the neon WARSZAWA POWIŚLE burns yellow on the saucer's
rim on the side the game's camera sees. Car collision round the upper hall (from the plinth's
foot to 4 m over the floor) and round the drum.

## 7. Detail level and budget

L3, budget 6800 triangles (in `check_mesh_quality.gd`; built 6186 after the 2026-11-06 rebuild: letters, bulbs, terrace and stage; was 1770).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| base | glass prism + mullions | the upper outline, 6 m | under the upper hall | glass | the escarpment's edge |
| upper_hall | glass panels | outline - 1.6 m | the upper outline | M_PAVILION | glass up to the roof |
| upper_roof | grid 10 x 10 | 3.4-7.0 m, twisted | over the upper outline | white / grey | the hypar, SE corner low |
| fascia | swept rib | 0.4 m | the roof's edges | brick brown | the hypar's edge |
| letters | neon | WARSZAWA POWIŚLE | over the doors, camera side | blue neon | the station's name |
| drum | glass prism | r 7.8 m, 3.4 m | (400.8, -6.3) | M_PAVILION | the round ticket hall, now a bar |
| saucer | rings | r 14.6 m, rim 4.5 m, dish 0.8 m | over the drum | white / grey | the inverted dome |
| neon | sign | WARSZAWA POWIŚLE | standing on the rim's edge, camera side | yellow neon | the bar's tube letters |
| canopies | slab + X supports | 72 m x 4.8 m, 3.6 m high | each side platform's middle | white / dark steel | the X canopies |

## 2026-11-13: tunnel mouth

OSM ended the four cross-city tracks on the pavilion's east face and 6 m north of it, so the
rails ran into the glass base and two stopped in the open. `Trains.TUNNEL_POWISLE` cuts all four on
one line 1.5 m in front of the face; the concrete headwall (`map_builder._build_rail_portals`)
stands there with every track going into the dark mouth.
