# Churches: design rules and the inventory (F, 2026-11-01)

F asked that **all the churches are designed with best practices**. This file is the rules every
church model follows and the list of every church the map has, with its status. The kit is
`landmarks.gd` `CHURCHES` / `_build_church` (spec `docs/landmarks/specs/churches.md`); the older
hand-built churches keep their own builders (listed below).

Current state, tiers and photo counts (2026-11-13): docs/LANDMARKS.md "Churches review". The table below is the 2026-11-01 kit inventory.

## The rules (what "designed properly" means here)

1. **Orientation.** The entrance faces the street, the apse the other way. The front end of the
   outline is the end nearest a road (found offline, stored as `o` and `out`). Photo check on the
   Mac fixes any church where the street is not the front.
2. **Keep the mapped plan.** The body is the OpenStreetMap outline itself on a plinth, so every
   transept, aisle, chapel and apse the map has stays; only the roof and the dressing are ours.
3. **One steep nave roof.** A gable along the long axis; the pitch by style (gothic 1.0, baroque
   and romanesque about 0.6, neoclassical 0.45, modern 0.4 of the half width). A cross plan gets
   a narrower nave roof over lower flat transept decks.
4. **A readable facade.** A portal with steps and a hood, a window (a rose in gothic and
   romanesque), corner pilasters, a string course, a pediment or gable. The entrance is always the
   strongest, darkest spot of the front.
5. **Towers by count, from a small table.** One on the axis or two flanking the front, a square
   shaft, a belfry with dark louvres, a cap by type: helm, dome, pyramid, spire, onion, ridge
   turret. Every cap carries a gilt cross. The tower is the church's silhouette: it is what the
   phone's far skyline shows.
6. **Wall rhythm.** Lesenes (baroque, romanesque) or buttresses (gothic) every 4.8 m on long
   walls; windows come from the building shader (`M_MONUMENT`) so they stay aligned.
7. **Style decides colour.** Baroque and neoclassical in cream plaster with copper-green or
   brown roofs; brick (neo-Romanesque, neo-Gothic) in red brick with a dark roof; modern
   parishes in pale plaster with a plain tall bell tower. No gold except crosses and onion domes.
8. **Cost.** All triangles go into the city's building surface (no new material, light or draw
   call); 250 to 950 triangles a church, budgets in `check_mesh_quality.gd`.
9. **Honesty.** Heights, towers and caps are estimates until a photo says otherwise; every model
   is a Mac photo check in QUESTIONS, and the card says only what the map and the name support.

## Styles in the kit

| Style | Used for | Eave / half width | Pitch | Towers |
| --- | --- | --- | --- | --- |
| baroque | the Old Town and New Town churches | 1.1 | 0.62 | 0-2, helm or dome |
| romanesque | brick Reformed church, Wola brick church | 1.25 | 0.6 | 1, pyramid |
| neogothic | brick parishes (Praga, Mokotów) | 1.4 | 1.0 | 1-2, spire |
| neoclassical | the Praga Trinity church | 1.1 | 0.45 | none |
| modern | 1980s-2000s parishes | 0.95 | 0.4 | 1, pyramid |
| orthodox | the Cerkiew | 1.1 | 0.5 | onion dome |

## Inventory

Status as of 2026-11-01. "Kit model" = built by the church kit; "model" = its own builder.

| Church (OSM name) | Kind | Centre (x, z) | Status |
| --- | --- | --- | --- |
| Cerkiew pw. Zaśnięcia Najświętszej Marii Panny | church | -1019, -1526 | kit model (`church_cerkiew`), 2026-11-01 |
| Dom Zakonny Sióstr Franciszkanek Służebnic Krzyża | monastery | -790, -1557 | open: convent or monastery: plain block, a later pass |
| Dom zakonny Księży Misjonarzy | monastery | -519, -547 | open: convent or monastery: plain block, a later pass |
| Kaplica Kościoła Baptystów | chapel | -2255, -359 | open: small chapel: a later pass |
| Kaplica pw. Matki Boskiej Częstochowskiej | church | 1725, -1677 | open: small chapel: a later pass |
| Kaplica pw. Świętej Barbary | chapel | -1103, 872 | open: small chapel: a later pass |
| Katedra polowa Wojska Polskiego Najświętszej Maryi Panny Królowej Polski | church | -1165, -1647 | kit model (`church_katedra_polowa`), 2026-11-01 |
| Klasztor Ojców Dominikanów | monastery | -961, -1965 | open: convent or monastery: plain block, a later pass |
| Klasztor Ojców Kapucynów | monastery | -1003, -1406 | open: convent or monastery: plain block, a later pass |
| Klasztor pallotynów | monastery | 1761, -1687 | open: convent or monastery: plain block, a later pass |
| Kościól Św. Karola Boromeusza | church | -2152, -461 | kit model (`church_karol`), 2026-11-01 |
| Kościół Ewangelicko-Reformowany | church | -1749, -1104 | kit model (`church_reformowany`), 2026-11-01 |
| Kościół Matki Bożej Jerozolimskiej | church | 984, 1319 | kit model (`church_jerozolimska`), 2026-11-01 |
| Kościół Niepokalanego Poczęcia Najświętszej Maryi Panny | church | -649, -1240 | kit model (`church_niepokalanego`), 2026-11-01 |
| Kościół Przemienienia Pańskiego | church | -975, -1432 | kit model (`church_kapucyni`), 2026-11-01 |
| Kościół Wizytek | church | -467, -787 | facade, wing and turret on kept skin (`wizytki`) |
| Kościół Wniebowzięcia Najświętszej Maryi Panny i świętego Józefa Oblubieńca | church | -582, -1036 | front on kept skin (`karmelici`) |
| Kościół Zielonoświątkowy | church | -1890, 332 | model from photos (`church_zielonoswiatkowy`, `_build_zielonoswiatkowy`, spec `zielonoswiatkowy.md`), 2026-11-14 |
| Kościół parafialny pw. Dzieciątka Jezus | church | -1825, 980 | model from photos (`church_dzieciatka`, `_build_dzieciatka`, spec `dzieciatka.md`), 2026-11-14 |
| Kościół parafialny pw. Narodzenia Najświętszej Maryi Panny | church | -1969, -976 | kit model (`church_narodzenia`), 2026-11-01 |
| Kościół pw. Matki Boskiej Zwycięskiej | cathedral | 1971, -1373 | kit model (`church_zwycieska`), 2026-11-01 |
| Kościół pw. Miłosierdzia Bożego i Świętej Faustyny | church | -2749, -693 | model from photos (`church_miloserdzie`, `_build_miloserdzie`, spec `miloserdzie.md`), 2026-11-14 |
| Kościół pw. Świętego Augustyna | church | -2417, -1176 | kit model (`church_augustyn`), 2026-11-01 |
| Kościół pw. Świętego Ducha | church | -1020, -1836 | kit model (`church_duch`), 2026-11-01 |
| Kościół pw. Świętego Jacka | church | -1011, -1913 | kit model (`church_jacek`), 2026-11-01 |
| Kościół pw. Świętego Krzyża | church | -473, -525 | model on kept skin: baroque facade and towers (`sw_krzyz`) |
| Kościół pw. Świętego Marcina | church | -795, -1584 | kit model (`church_sw_marcin`), 2026-11-01 |
| Kościół pw. Świętej Anny | church | -658, -1350 | model, kept skin: portico and tower trim (`sw_anna`, #211 deck people) |
| Kościół pw. Świętych Apostołów Piotra i Pawła | church | -1129, 830 | kit model (`church_piotr_pawel`), 2026-11-01 |
| Kościół Świętego Antoniego Padewskiego | church | -1211, -978 | kit model (`church_antoniego`), 2026-11-01 |
| Kościół Świętej Trójcy | church | -855, -511 | model (`trojca`, Zug's rotunda) |
| Kościół Świętej Trójcy | church | 1071, 263 | kit model (`church_trojca_praga`) |
| Kościół św. Brata Alberta i św. Andrzeja Apostoła | church | -1074, -1133 | kit model (`church_alberta`), 2026-11-01 |
| Matki Bożej Częstochowskiej | church | 1132, 868 | kit model (`church_czestochowska`), 2026-11-01 |
| Monaster Zaśnięcia Najświętszej Bogurodzicy i św. Jozafata biskupa i męczennika | monastery | -1025, -1518 | open: convent or monastery: plain block, a later pass |
| Parafia Świętej Teresy od Dzieciątka Jezus | church | 370, -579 | model (`teresy`, #225) |
| Sala św. Faustyny | chapel | -2792, 1574 | open: small chapel: a later pass |
| Synagoga Nożyków | synagogue | -1565, -229 | whole model from photos (`_build_nozyk`, spec `nozyk.md`), 2026-11-14; the kit's front faced east |
| Zgromadzenie Sióstr Franciszkanek Rodziny Maryi | religious | -2617, -739 | open: convent or monastery: plain block, a later pass |

Also on the map (no model): the Archikatedra św. Jana (`archikatedra`, front on the kept skin,
PR #167) and the Barbican's neighbours are the Old Town lane's; Praga's cathedral (Bazylika
Katedralna św. Michała i św. Floriana) is still open (LANDMARKS 3.2). 21 unnamed religious
buildings (convent wings, chapels, parish halls) stay plain blocks.

## Targets

- [x] The kit and its first 22 churches (2026-11-01).
- [ ] Mac photo check of every kit church (QUESTIONS): front side, tower count and cap, colours.
- [ ] Praga cathedral, Archikatedra's tower, the Dominican and Capuchin monasteries as models.
- [ ] Church interiors are out of scope; night lighting for the towers' belfries (a lit louvre
      stage) is the next polish.
