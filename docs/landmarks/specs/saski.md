# Saski Crescent and Senator: spec

Site keys `saski` and `senator` in `game/scripts/landmarks.gd` (SKINS). Written 2026-11-07 in a
cloud thread from F's photos on the Mac (`warsaw-other-buildings-part-2`, rows M571 Królewska 16 and
M551 Bielańska 12, a street view and aerials) and the outlines in `centrum.json`. Both keep their
LoD2 mass in a kept skin; no model. Values marked *(photo check)* wait for a Mac walk.

## 1. Identity

Saski Crescent is a ten-storey glass office whose east face bends in a long curve towards the
Saxon Garden: green-teal curtain wall with dark floor bands, a grey stone-clad eight-storey wing on
the Królewska side, a dark crowning band and a recessed glass entrance under a canopy (M571).
Senator, on Bielańska and the Saxon Garden's edge, is a pale-clad office with a big flat roof,
a triangular glass light well and a glass atrium ridge (M551).

## 2. Massing

Saski Crescent: outline `Saski Crescent` (44 corners round (-1320, -465), 30.7 m); the curve lies along its
south-east side. Senator: outline `Senator` (124 corners round (-1250, -1240)), 14 m mapped
*(photo check: seven storeys in the photo)*. Heights stay LoD2's.

## 3. Facade, base to top

Saski Crescent in the monument-free curtain-wall code M_GLASS, wall colour #5f948f (the photo's
teal-green, kept a step calmer). Senator in the re-clad code M_SKIN + S_PUNCHED (light cladding,
punched windows in bands), #dbd0bc. Not modelled yet: the stone wing (#9a9c9d), the canopy and the
dark crown band with its sign.

## 4. Roof

Saski Crescent #7d8589 (grey membrane and plant); Senator #a3a7a8 (grey membrane, from the
aerial: a flat roof with a glass light well that is not modelled).

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Saski Crescent wall | #5f948f | M_GLASS |
| Saski Crescent roof | #7d8589 | roof |
| Senator wall | #dbd0bc | M_SKIN + S_PUNCHED |
| Senator roof | #a3a7a8 | roof |

No new material or draw call.

## 6. Ground and night

Nothing new at the foot. Open: the crown sign for Saski Crescent must be a parody (SASKI ROGAL), a
mapped-parts tower build for the stone wing and the dark crown, the glass light well on Senator.

## 7. Detail level and budget

L1 skins, no triangles added; triangle budget 200 (exception: none used).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| saski skin | kept LoD2 mass | 44-corner outline, 30.7 m | (-1320, -465) | M_GLASS | 1 teal curtain wall |
| senator skin | kept LoD2 mass | 124-corner outline | (-1250, -1240) | M_SKIN + S_PUNCHED | 1 pale cladding |
