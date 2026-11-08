# InterContinental (Emilii Plater 49): spec

Site key `plater49` in `game/scripts/landmarks.gd` (`TOWERS` entry, built by `_build_interkonti`). Written 2026-11-08 in a cloud thread from F's four photos (`/mnt/project-files/pkin-surroundings/photos/W1-intercontinental/`: 1 the front from the Palace's steps at dusk, 2 the aerial over Osiedle Emilia, 3 the north view up Emilii Plater, 4 the night view with the Palace) and the OpenStreetMap parts in `centrum.json`. Mapillary street views (`refs/plater49/street/`, CC BY-SA 4.0) were looked at for the podium only. Brand as the parody INTERKONTI.

## 1. Identity

1. The great gap: from the podium's roof to the 20th floor the shaft's north-east half is missing, so the hotel floats over a 53 m high hole open towards the Palace (photos 1, 3, 4).
2. The gap's back wall is pale stone and its ceiling warm; at night the whole hole is floodlit white (photo 4).
3. A slim square shaft in silver-blue glass in a white grid, turned like the street grid.
4. The roof cut on a slope: high over the south-west face, lower over the north-east one (photo 1).
5. A one-bay glass column running down the north corner beside the gap (photo 1).

## 2. Massing

From the mapped parts: the podium is the site's outline (about 42 x 42 m) to 16.5 m; the shaft a square of about 31 m a side (`IC_SHAFT`). Under the gap (16.5 to 69.3 m) only the shaft's south-west half stands (`IC_LOWER`, cut on the diagonal from the north-west face to the east corner) and a 5 m column at the north corner (`IC_COLUMN`). Over the gap the whole shaft rises to a roof cut on one plane: 164 m over the south-west face, 154 m over the north-east one.

## 3. Facade, base to top

Base: four storeys of glass in light horizontal bands (S_BANDS), to 16.5 m. Middle: the S_GRID skin (white grid, fine storey lines) on every glazed face; the gap's back wall plain stone. Top: a dark storey band right over the gap (69.3 to 73.1 m) and the dark top storeys (146 to 153.6 m) as rings 0.1 m proud of the glass; the name over them.

## 4. Roof

Cut on a slope with `_tower_cut` (`cut_drop` 10 m, rising to the south-west), pale grey; red aviation lights on three corners at the roof's height there. No plant modelled (the photos show none from the street).

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Shaft glass | #7f98ab | M_SKIN S_GRID |
| Podium glass | #9db3bd | M_SKIN S_BANDS |
| Gap back wall | #d2cbbb | M_LAMP (plain by day, floodlit white at night) |
| Gap ceiling | #e6cf9e | M_LAMP |
| Dark bands | #2a3440 | M_SKIN S_DARK |
| Roofs | #c3c7c9, #b9bec0 | M_STONE |

No new material or draw call: everything goes into the site's building mesh.

## 6. Ground and night

The podium carries its own car walls (the site outline). At night the gap glows white with a warm ceiling, the grid's windows light by the skin's rule, the INTERKONTI name burns warm on the dark top band, red lamps on the roof.

## 7. Detail level and budget

L2; budget 140 triangles in `check_mesh_quality.gd` (91 measured): the model is plain prisms, the identity is in the massing.

Shots: `--at=-1470,180 --yaw=90 --lift=85 --size=200` (from the Palace, photo 1) and `--yaw=180` (from the north, photo 3), day and night; `--solo=plater49 --solo-look=lit`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| podium | site outline prism | 42 x 42 m, 16.5 m | ground | S_BANDS glass | 3 |
| lower | quadrilateral prism (shaft's SW half) | 16.5 to 69.3 m | under the gap | S_GRID glass | 1 |
| back wall | wall on the diagonal | 36 m x 52.8 m | gap's back | M_LAMP stone | 2 |
| column | triangle prism | 5 m a side | north corner | S_GRID glass | 5 |
| ceiling | triangle soffit | the gap's plan | 69.3 m | M_LAMP warm | 2 |
| shaft | square prism, cut roof | 31 m, 69.3 to 154-164 m | over all | S_GRID glass | 3, 4 |
| bands | rings 0.1 m proud | 3.8 m and 7.2 m | 69.3 m and under the roof | S_DARK | 3 |
| name | neon INTERKONTI | crown share 0.7 | top band | sign | 3 |
