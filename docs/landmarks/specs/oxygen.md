# Oxygen (Wola)

Site key `oxygen`, a whole-building model in `game/scripts/landmarks/wola.gd`.
The seven local obliques in `refs/oxygen/3dtiles/` show the nearly square
courtyard, curved street walls and open roof terraces.

## 1. Identity

Oxygen is a courtyard block with round corners and deep, pale horizontal
bands on the street. The inner elevations have a warmer colour and more
vertical balcony stacks. The map tags it as apartments, matching the court
balconies and repeated terraces visible in the references.

## 2. Massing

The named OSM outer ring (centrum building 12682) spans x −2731.5 to
−2652.0 and z −128.5 to −45.6. The local origin is (−2691.75, −87.05)
and u runs east along vector (60, −17) normalized. Axis v points south
perpendicular to u. The mapped sides bow gently, with tighter curves at
all four corners. The estimated court spans about 44 by 42 m at u −21 to
23 and v −21 to 21. The lower terrace deck reaches 27.5 m, while the
main roof and recessed top-floor volumes reach about 30.7 m, the OSM
height tag. Oxygen is in `keep_osm`, so its generic mass comes from
the OSM outline in the supplied bake.

## 3. Facade, base to top

- **Street base.** Darker stone and taller glazing, with a door on the
  north street below the pale bands.
- **Street elevations.** Seven levels of narrow dark ribbon glazing
  alternating with tall bands of grey-beige cladding. Follow the curved
  sides with five- to six-metre bays and small variations in pane width.
- **Court elevations.** Eight rows with pale upright wall strips between
  dark, broad balcony openings, alternating with a narrower window.
  A projecting ledge runs under the balcony rows.
- **Upper tier.** A continuous roof over the south and west sides. On
  the north and east, a recessed top floor and short glazed front rooms
  leave the terrace deck visible between them.

## 4. Roof

Pale gravel on the broad south and west roof strips. Darker terrace paving
on the north and east, with pale coping and short walks between the rooms.
The vents are grouped above the long roof strips and the recessed top floor.
The roof wraps the court without bridging it.

## 5. Colour and material

Grey-beige stone on the street, warmer cream within the court, pale concrete
on the rims and pale warm-grey gravel on the roof. Stone and concrete use
`M_STONE`; blue-grey street ribbons and slightly warmer inner openings
use the kit's `M_PANE`.

## 6. Ground and night

Set a common ground datum from the mapped outline. Sink the facade feet
0.7 m and give the outer outline and the court walls collision.
Keep the court floor open to the terrain and let the shared kit light
individual panes at night.

## 7. Detail level and budget

L3, triangle budget 3500. Spend geometry on the curved outline, the
courtyard and the stepped roof. Use a quad for each shared-kit pane and
group the small roof vents.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| mass | rounded ring around a rectangular opening | about 84 x 72 m, deck at 27.5 m | mapped outline | M_STONE | rounded street frontage and open court |
| glazing | kit panes, doors and ledges | 7 exterior and 8 court rows | street facades and court walls | M_PANE / M_STONE | narrow street ribbons and tall inner balcony openings |
| terraces | high roof strips, recessed tier and glazed rooms | about 3.2 m above the deck | north and east terraces, south and west roof | M_STONE / M_PANE | stepped top floor |
| plant | coping and grouped boxes | vents up to 1.2 m | long roof strips and top floor | M_STONE | pale rims and scattered vents |

## 9. Left out

Subdivision of every terrace, roof vents too small to read in the obliques,
and interior rail details. The courtyard dimensions and terrace partitions
are estimated from the rooftop views.
