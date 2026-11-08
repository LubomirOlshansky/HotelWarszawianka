# Prosta 32 (ul. Prosta 32, Wola): spec

Site key `prosta32` in `game/scripts/landmarks.gd` (`_find_prosta32`, `_build_prosta32`,
`_p32_lattice`, `_p32_member`, `_p32_proud`). Built 2026-11-06 from F's ten photos of the tower
and its neighbour (street views from Prosta's south side, from the east along Prosta, two aerials,
a close-up of the arches at the foot, an architect's render), the OSM outline "Prosta Tower" and
its two parts, and GUGiK LoD2 (2018: 77 m over the ground with the roof kit). The developer's red
roof letters are never written: the roof says MARZYPOL, a parody.

## 1. Identity

1. **The lattice**: a white concrete diamond lattice over the whole Prosta (south) front, seven
   diamonds across, about sixteen up, standing out from the glass by a depth that swells and
   shrinks up the height, so the front's edge waves in profile.
2. **Blue glass** everywhere else: the west, north and east faces are plain deep-blue mirror glass.
3. **Arches at the foot**: the lowest diamonds open onto the pavement, the members landing as legs.
4. **MARZYPOL** in red letters on the roof edge over the lattice and over the east face.

## 2. Massing

The tower part (OSM 70 m, about 25 x 17 m) built to 74 m (LoD2's 77 m less the roof kit); the
east part (OSM 3.3-14.2 m) as a four-storey glass podium to 14.2 m. Both from their mapped outlines.

## 3. Facade, base to top

- Tower: M_SKIN S_MIRROR #3d6c9c from the ground to 74 m on every face.
- Lattice on the south edge (the outline's edge facing +z the most): nodes every 1.8 m across
  (14 half-diamonds) and every 2.3 m up (diamonds 3.6 x 4.6 m); two families of diagonal members,
  1.0 m wide on the face, front faces 0.45 to 1.3 m proud of the glass (a sine wave of 26 m period
  up the height), sides running back to the glass; the "\" family 6 cm prouder than the "/" so the
  crossings don't z-fight. Lowest nodes on the ground (the arches). A white head band 0.5 m deep
  over the last row, to the roof.
- Podium: M_SKIN S_BANDS #6f8ea6, parapet 0.8 m.

## 4. Roof

Grey #8e979e, a 1.1 m parapet, one plant box 6 x 6 x 2.6 m. MARZYPOL stands on the roof edge.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Glass | #3d6c9c | M_SKIN S_MIRROR |
| Lattice | #e9e7e1 (sides 8 % darker) | M_STONE |
| Podium | #6f8ea6 | M_SKIN S_BANDS |
| Roof, parapets | #8e979e | M_STONE |
| MARZYPOL | red (0.92, 0.12, 0.12) | neon word |

## 6. Ground and night

The lattice's legs stand on the pavement of Prosta; the low office and tram stop next door stay
the map's. At night the glass shows the skin's lit windows through the lattice; MARZYPOL is a neon
word. Car walls: both mapped outlines (`_collide`, handed to `pocket_rings`).

## 7. Detail level and budget

L3, triangle budget 3300 (2722 measured plus 20 %; the lattice is about 480 members of six
triangles, one landmark mesh, no new draw call). Shots: `--at=-2415,305 --yaw=0` (from the
south-east, as the aerial), `--yaw=80` (from the south-west, as the street photos).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| tower | prism of the outline | 74 m | OSM tower part | M_SKIN S_MIRROR | 2 glass |
| lattice | about 480 diagonal members | 1.0 m wide, 0.45..1.3 m proud | south face | M_STONE | 1 lattice, 3 arches |
| head | band | 0.5 m | top of the lattice | M_STONE | 1 lattice |
| podium | prism of the outline | 14.2 m | OSM east part | M_SKIN S_BANDS | 2 glass |
| plant | box | 6 x 6 x 2.6 m | roof | M_STONE | 4 roof |
| sign | 2 neon words | scale 1.4 and 0.95 | south and east roof edges | neon | 4 sign |
