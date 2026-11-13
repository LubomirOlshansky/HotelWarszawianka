# Spektrum Tower (Twarda 18) and its rooftop club: spec

Site key `spektrum` in `game/scripts/landmarks.gd` (`TOWERS` entry, built by `_build_spektrum`). Written 2026-11-13 in a cloud thread from eleven photos F sent in the project thread (reference only, never shipped): S-01 the tower at dusk from Twarda, S-02 a night render of the podium and crown, S-03 the aerial from the west (urbanity), S-04 and S-06 the drum and fin from the south-east, S-05 the crown at night by the Palace, S-07 to S-11 the rooftop club by day, at dusk and at night. Massing from the OpenStreetMap / LoD2 parts in `centrum.json`. The tower's name sign is the parody SPEKTRAL, the club's the parody THE WJU.

## 1. Identity

1. A round drum of pale blue glass in white aluminium bands, flanked by dark square-grid slabs that stop a few storeys under its top (S-01, S-03, S-06).
2. The slanted glass fin: a pale green glass wedge in the notch on the drum's south face, wide over the podium and leaning in until it meets the drum near the top (S-03, S-04, S-06).
3. The crown: a ring of tall glass screens round the drum's roof, a blue LED rail on top at night (S-01, S-05, S-08).
4. The club on the roof: a raised round deck behind a glass railing, its edge a lit ring at night, white lounge chairs, curved sofas, poufs and cube tables, palms in white pots, white parasols, a round bar in the middle (S-07, S-09, S-10, S-11).
5. The podium: a glazed ground floor, grey storeys over it, a white edge at the roof (S-02, S-06).

## 2. Massing

From the mapped parts: the drum to 122 m (about 32 m across), the slabs to 106 and 118 m, the podium parts 12 to 36 m round the foot, the low wing south towards Twarda. The mapped crown ring (122 to 128 m) and the roof box (128 to 133 m) are not built: the screens and the club stand there, the club deck at 125.4 m and the furniture on it, near the real 128 m.

## 3. Facade, base to top

Podium: glazed hall to 5.4 m (S_GRID, pale blue glass), grey ribbon storeys (S_RIBBON), a 1.1 m white roof edge. Tower: the drum S_BANDS #5f86a3, the slabs S_GRID #26384a. The fin: two glass sides (M_GLASS) and a sloping face from the podium roof at 32 m, 30 m out from the drum's centre, to the drum at 117 m; 2.5 m thick; a pale tube up its slope that glows at night (M_LAMP).

## 4. Roof

Screens 0.2 m outside the drum from 3.2 m under its roof to 2.4 m over it (M_GLASS, both faces), steel posts every second panel, a rail on top (M_LAMP 0.5: blue at night). Inside: the lower deck dark grey. The club: a grey metal drum 72 % of the drum's radius, 3.4 m high, the top 0.55 m a warm lit band (M_LAMP), a pale deck, a 1.1 m glass railing with a steel top rail. On the deck: the round bar (white counter ring, dark floor), six lounge groups round it (four armchairs round a lit cube table, and curved five-piece sofas round a lit cube and two poufs, by turns), the DJ's booth to the north (black desk with a lit pink front, two speaker stacks, a lit truss bar), six palms in tall white pots by the railing, three white parasols.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Drum glass | #5f86a3 | M_SKIN S_BANDS |
| Slabs | #26384a | M_SKIN S_GRID |
| Podium hall / storeys / edge | #9cb8c4 / #8a959b / #e9ecec | S_GRID / S_RIBBON / M_STONE |
| Fin | #9cc6c2 | M_GLASS |
| Screens | #a8cbcb | M_GLASS |
| Lower deck / club wall / club deck | #5c6469 / #a3a9ad / #cfd1cd | M_STONE |
| Lit ring / LED rail | #ffe6b0 / #c7d4de | M_LAMP / M_LAMP 0.5 |
| Furniture / cube tables | #f1eee6 / #fff3dc | M_STONE / M_LAMP |
| Palms | trunk #6b5a44, fronds #4f7a3a | M_STONE |

No new material, shader branch or draw call: everything goes into the site's building mesh, the two names into the landmark signs.

## 6. Ground and night

People (crowds.gd `spektrum_view`, `spektrum_dj`, from `Landmarks.spektrum_plan`, the model's own layout): loungers in the seats from 12:00 to 02:00, the DJ and up to 14 dancers facing the booth from 19:00; fuller on Friday and Saturday and in season, thinner in rain. The DJ's music: city_sounds kind `rooftop` (techno_thump) at the deck while the DJ plays.


The podium and the tower carry the car walls. At night the glass lights by the skin's rule, the club's edge burns warm white, the screens' rail blue, the cube tables glow, the fin's edge is a pale line; SPEKTRAL in pale white on the south and north screens, THE WJU in pink on the east and west.

## 7. Detail level and budget

L3 (a landmark seen close from the helicopter and the roof), triangle budget 3900 (built: 3567). One building mesh, +0 draw calls, no new material or shader branch.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| SP-1 | mapped drum, prism | about 32 m across, 122 m | the outline's middle | M_SKIN S_BANDS #5f86a3 | blue glass in white bands (S-01, S-06) |
| SP-2 | mapped slabs, prisms | 106 and 118 m | round the drum | M_SKIN S_GRID #26384a | dark square grid (S-03) |
| SP-3 | podium parts, prisms | 12 to 36 m | round the foot, wing to Twarda | S_GRID / S_RIBBON / M_STONE | glazed hall, grey storeys, white edge (S-02) |
| SP-4 | fin, wedge | 2.5 m thick, 32 to 117 m, 15 m out at the foot | the drum's south notch | M_GLASS #9cc6c2, lit edge M_LAMP | the slanted glass fin (S-03, S-04, S-06) |
| SP-5 | screen ring, 32 sides | drum radius + 0.2 m, 3.2 m under to 2.4 m over the roof | the drum's top | M_GLASS #a8cbcb, posts, rail M_LAMP 0.5 | the crown's glass screens, blue rail (S-05, S-08) |
| SP-6 | club drum, 28 sides | 72 % of the drum's radius, 3.4 m | on the drum's roof | M_STONE, lit band M_LAMP | the raised deck and its lit ring (S-07, S-09) |
| SP-7 | railing ring | 1.1 m | the club deck's edge | M_STONE #c3dad9 | glass railing (S-10) |
| SP-8 | lounge groups, boxes | chairs 0.72 m, tables 0.64 m | 8 round the bar | M_STONE white, tables M_LAMP | white lounge, glowing cube tables (S-10, S-11) |
| SP-9 | palms in pots | pot 1 m, palm 3 to 3.8 m | 6 by the railing | M_STONE | terrace palms (S-10) |
| SP-10 | bar and parasols | bar 4.4 m across, parasols 3 m | the middle | M_STONE white | round bar, white parasols (S-09) |
| SP-11 | signs | 10 m and 7 m wide | screens N/S and E/W | landmark neon | SPEKTRAL, THE WJU |
