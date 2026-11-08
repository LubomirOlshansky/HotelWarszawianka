# Wola's "19. Dzielnica": the Kolejowa estate, Asbud's towers and the drug works' building site (sites `noho`, `d19`, `asbud`)

F's ask (2026-11-07): "make the dzielnica 19 like real, and the construction work where Polfa was
and NOHO ONE in construction", with eleven photos.

## Sources

- F's eleven photos (2026-11-07, kept in the project files, never in the repo): three drone views of
  the estate (cream blocks with brown window frames; a plaza with dark grey frames and a grass mound),
  the courtyard with the glass footbridge, five photos of the Towarowa Towers (dark blue glass, gold
  and orange frames, white spine, orange base, the ASBUD mark on the crown), a satellite crop of
  Kolejowa, Przyokopowa and Kasprzaka, Street View of the estate's last stage as concrete frames, the
  drug works' plot as a site (a long concrete frame, a green tower crane, pallets of white, blue and
  pink insulation, cabins, cars, sand) and NOHO ONE's hoarding on a frame.
- whitemad.pl, architekturaibiznes.pl, eurobuildcee.com: NOHO ONE (BBGK Architekci) is on the former
  Polfa pharmaceutical works, about 5 ha by Prosta/Kasprzaka; precast concrete and stone, round
  columns, cornices; the "cascades" are terraces stepping down from penthouses; the first phase has
  its permit; Atlas Ward builds it.
- otodom/tabelaofert listings: "19. Dzielnica" is the estate on Kolejowa and Przyokopowa.
- OpenStreetMap: the plot is `landuse=construction`; the estate is 58 mapped parts (podiums 4.3 m,
  blocks 14-34 m, set-back top floors); the Towarowa Towers are two 96.7 m `apartments` outlines.

Brand rule: the site's name is the parody OHO ONE, the contractor's ATLAS WIATR, the developer's
ASBUDKA. The estate's name is a place name (like Osiedle Za Żelazną Bramą). The card does not name
the drug company: "medicines were made here".

## 1. Identity

Three sites in one corner of Wola. `noho`: the former drug works' plot on Kasprzaka as NOHO ONE's
live building site (parody OHO ONE), bare concrete frames, three cranes and a busy yard. `d19`: the
"19. Dzielnica" estate on Kolejowa and Przyokopowa, cream blocks with rust window frames and two
white-and-gold blocks behind a dark grid on the east green. `asbud`: the Towarowa Towers, two 96.7 m
towers of dark blue glass in orange and gold frames (developer parody ASBUDKA).

## 2. Massing

Frame D19_O/A/B: u along Kasprzaka (east), v into the plot (south). `noho`'s zone is the
OpenStreetMap `construction` outline (NOHO_PLOT) plus the strip south of it to the diagonal street's
kerb (NOHO_STRIP, the estate's last stage): four frames of 3.2 m storeys: the long one and the Kasprzaka one topped out at 11 storeys (F's
October photos: glazed to 10, the top storey open, scaffolding with red-and-white boards round
them; the long one's top 3 storeys step back 3.5 m a storey on the west as the cascade's
terraces), the last stage's two at 8, two 12-storey cores, a raft.
`d19` rebuilds every mapped part in D19_ESTATE from its outline (simplified 5 cm, the parts share
fronts): podiums up to 5 m, blocks 14-34 m with set-back top floors, `roof` parts as 0.4 m canopies.
`asbud` rebuilds the parts in ASBUD_ZONE: the two towers (parts over 60 m, simplified 1.5 m) and the
white blocks beside them.

## 3. Facade

- Frames: perimeter columns every 8 m, the lowest floors glazed in dark glass 0.6 m in, 1.08 m
  safety screens with a yellow top on the open floors; the last stage's slabs run 1.4 m out as
  balconies on the long sides (Street View).
- Hoarding: 2.4 m dark grey boards with OHO ONE along Kasprzaka and the east street, galvanised panels
  elsewhere, three gates.
- Estate look 0: S_PUNCHED cream with rust frames (4 cm proud, the pane 8 cm proud) round about a
  third of the windows, scattered; a dark shop band 40 cm in on the ground floor. Look 1 (the two
  blocks east of x -2880, south of z 735, the plaza photo): bronze glass (S_GOLD) behind a charcoal
  grid, a floor band every 3 m and a pier every 6 m, white short ends.
- Towers: shop glass to 5.4 m, an orange band 5.4-7.6 m, dark blue glass (S_DARK) to the roof, a
  white stone spine 4.4 m wide a fifth of the way along the longest front; frames every 4.2 m in
  three-storey pieces (every other one shifted a storey and a half), orange up to 40 % of the
  height, gold above, 0.3 m proud. White blocks: S_PUNCHED with orange panels up one window column
  in six.
- Fronts shared by two parts are dressed once or not at all (`_d19_party`, `_d19_decorated`,
  `_d19_clash`), so nothing flickers.

## 4. Roof

Frames: bare top slab, no parapet. Estate: flat light roof (#b9b7b1), a plant room on roofs over
500 m², podiums over 600 m² get a garden roof. Towers: the frames run 4.5 m past the roof as an open
crown, ASBUDKA in green neon on it.

## 5. Colour and material

Concrete #b8b5ae, glass #3e5560, safety rail #d8c23a, hoarding grey #454c53, scaffold boards red #c8322e and white #d9d6cf, panels #8e9497, cranes
green #4f8a3c, red #c8322e, white #d9d6cf. Estate cream #dfcdb0, rust #94573a, pane #2c343b, bronze
#7b6450, charcoal #3f4245, white #eceae4, garden #7f9b58, shop glass #2f383f. Towers glass #2f4d6c,
gold #c9a24c, orange #d5562a, stone #e4e1da.

## 6. Ground and night

The plot's ground is not flat: every yard item, fence piece, frame and core sits on its own terrain
sample (`_gy`, `_gy_rect`). The car collides with the hoarding (both rings), each frame and the
estate's blocks; laser-scan trees on the plot are dropped (tree_free). Night: crane lamps red, OHO
ONE, ATLAS WIATR and ASBUDKA lit (neon_signs LANDMARK_WORDS).

## 7. Detail level and budget

L3 with a named exception: these are three whole quarters, not one building. Triangle budget 12700
for `noho` (the build is 8278), 9000 for `d19` (8150), 3900 for `asbud` (3194), the sites' entries in
`check_mesh_quality.gd`. No new materials, so no new draw calls.

## 8. Parts table

| Part | Shape | Size | Position (u, v) | Material | Feature |
| --- | --- | --- | --- | --- | --- |
| Long frame | slabs, columns, screens | 32 × 96 m, 11 storeys, scaffolded | 150-182, 22-118 | concrete, dark glass, yellow rail | the cascade's stepped terraces |
| Kasprzaka frame | slabs, columns, 2 cores | 68 × 18 m, 11 storeys, scaffolded, cores 12 | 70-138, 9-27 | concrete, dark glass | cores rising ahead of the floors |
| Last stage | two frames with balcony slabs | 50 × 26 m and 44 × 23 m, 8 storeys | 70-120, 161-187; 136-180, 149-172 | concrete, dark glass | the Street View frames |
| Foundation slab | raft, starter columns | 32 × 40 m, 30 columns | 8-40, 116-156 | concrete, steel bars | the next block starting |
| Cranes | lattice mast, jib, counter-jib | 46, 42, 38 m masts | (143, 72), (104, 38), (127, 167) | green, red, white steel | red lamp on top |
| Yard | pallet blocks, cabins, container, silo, skip, heaps, digger, cars | 55-145 × 34-122 m | across the plot | EPS white, XPS blue, pink, cabins with a red band | ATLAS WIATR cabins |
| Hoarding | boards in 12 m pieces | 2.4 m high | round both zones | dark grey boards, galvanised panels | OHO ONE, three gates |
| Estate blocks | rebuilt outlines | 58 parts, 4.3-34 m | D19_ESTATE | cream S_PUNCHED, rust frames; S_GOLD + charcoal grid | 19. Dzielnica's look |
| Towers | rebuilt outlines, fins, crown | 2 × 96.7 m | ASBUD_ZONE | blue glass, orange and gold frames, stone spine | ASBUDKA crown |

## Defaults until F's photos say otherwise

The list is /mnt/project-files/dzielnica19/PHOTOS-NEEDED.txt. Defaults built: storey counts of the
frames, where the long frame stands (the yard photo puts it on the east of the plot), which estate
blocks wear the dark grid (the two on the east green), the crane count and colours.
