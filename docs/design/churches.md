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

Status as of 2026-11-15 (after #785). Every church in this table now has its own builder; none is left on the kit. Still open: the convent wings and unnamed religious blocks (21 in the map) are plain blocks or, like the Wizytki convent, built from LoD2 with default colours because no open photo reaches them; the Archikatedra's side walls and east end stay the LoD2 mass in brick: the Kanonia and Dziekania houses hide almost all of them, and the 2026-11-14 photos (Commons and Mapillary, 14 more round the east end on 2026-11-15) show only interiors and the neighbours. One combined phone measurement of the whole church set is on the next-build list.

| Church (OSM name) | Kind | Centre (x, z) | Status |
| --- | --- | --- | --- |
| Cerkiew pw. Zaśnięcia Najświętszej Marii Panny | church | -1019, -1526 | model from LoD2 and the street front (`church_cerkiew`, `_build_cerkiew`, spec `cerkiew.md`), 2026-11-14 |
| Dom Zakonny Sióstr Franciszkanek Służebnic Krzyża | monastery | -790, -1557 | model from 9 Commons photos and LoD2 (`church_franciszkanki_piwna`, `_build_franciszkanki_piwna`, spec `franciszkanki_piwna.md`), 2026-11-14: ochre ranges round St Martin's chancel, the Piwna front with its stone portal, hipped roofs |
| Dom zakonny Księży Misjonarzy | monastery | -519, -547 | the street wing and the Karowa wing (OSM building 7141, -500, -567) are a model from 8 Commons photos and LoD2 (`church_misjonarze`, `_build_misjonarze`, spec `misjonarze.md`), 2026-11-14: the 17-bay ochre front, white rusticated ground floor, eleven dormers; this back wing stays the plain block |
| Dom Księży Misjonarzy (Radna 14) | monastery | -66, -752 | model from 7 Commons photos and LoD2 (`church_misjonarze_radna`, `_build_misjonarze_radna`, spec `misjonarze_radna.md`), 2026-11-14: the cream front, the portal with the Virgin in her blue niche, the chapel block behind |
| Kaplica Kościoła Baptystów | chapel | -2255, -359 | model from 8 Commons photos and LoD2 (`church_baptysci`, `_build_baptysci`, spec `baptysci.md`), 2026-11-14: the grey concrete box over a glazed ground floor, the dark cross |
| Kaplica pw. Matki Boskiej Częstochowskiej (Kościół Chrystusa Króla Pokoju) | church | 1725, -1677 | model from 7 Commons photos and LoD2 (`church_chrystusa_krola`, `_build_chrystusa_krola`, spec `chrystusa_krola.md`), 2026-11-14: the cream chapel on the street with its white tower, the square church behind under a brown pyramid roof and lantern, the parish wings |
| Kaplica pw. Świętej Barbary | chapel | -1103, 872 | model from 2 Commons photos and LoD2 (`church_barbara`, `_build_barbara`, spec `barbara.md`), 2026-11-14: red brick, steep dark roof, gables at both ends, low annex |
| Kościół Adwentystów Dnia Siódmego (Foksal 8; unnamed in OSM) | church | -82, -52 | LoD2 mass in its skin plus a model gate, balconies and name band (`adwentysci`, `_build_adwentysci`, spec `adwentysci.md`), 2026-11-15 from 5 Commons photos: the pale yellow house behind its front garden |
| Katedra polowa Wojska Polskiego Najświętszej Maryi Panny Królowej Polski | church | -1165, -1647 | whole model from photos (`church_katedra_polowa`, `_build_katedra_polowa`, spec `katedra_polowa.md`), replacing the 2026-11-01 kit model |
| Klasztor Ojców Dominikanów | monastery | -961, -1965 | model from LoD2 and a photo (`church_dominikanie`, `_build_dominikanie`, spec `dominikanie.md`), 2026-11-14: the wings round the cloister, the galleries, the east wing down the slope |
| Klasztor Sióstr Wizytek | convent | -429, -826 | model from LoD2 (`church_wizytki_klasztor`, `_build_wizytki_klasztor`, spec `wizytki_klasztor.md`), 2026-11-15: four ranges round a closed courtyard, steep hipped roofs; colours and windows are defaults (no open photo reaches it) |
| Klasztor Ojców Kapucynów | monastery | -1003, -1406 | model from 12 Commons photos and LoD2 (`church_kapucyni_klasztor`, `_build_kapucyni_klasztor`, spec `kapucyni_klasztor.md`), 2026-11-14: pale yellow three-storey ranges round the courtyard, hipped green copper roofs |
| Klasztor pallotynów | monastery | 1761, -1687 | model from LoD2 and a photo (`church_pallotyni`, `_build_pallotyni`, spec `pallotyni.md`), 2026-11-14: the 1930s modernist block, ribbon windows, terraces |
| Kościól Św. Karola Boromeusza | church | -2152, -461 | model from photos (`church_karol`, `_build_karol`, spec `karol.md`), 2026-11-14 |
| Kościół Ewangelicko-Reformowany | church | -1749, -1104 | model from photos (`church_reformowany`, `_build_reformowany`, spec `reformowany.md`), 2026-11-14 |
| Kościół Matki Bożej Jerozolimskiej | church | 984, 1319 | model from photos (`church_jerozolimska`, `_build_jerozolimska`, spec `jerozolimska.md`), 2026-11-14 |
| Kościół Niepokalanego Poczęcia Najświętszej Maryi Panny | church | -649, -1240 | whole model from photos (`church_niepokalanego`, `_build_niepokalanego`, spec `niepokalanego.md`), replacing the 2026-11-01 kit model |
| Kościół Przemienienia Pańskiego | church | -975, -1432 | whole model from photos (`church_kapucyni`, `_build_kapucyni`, spec `kapucyni.md`), replacing the 2026-11-01 kit model |
| Kościół Wizytek | church | -467, -787 | facade, wing and turret on kept skin (`wizytki`) |
| Kościół Wniebowzięcia Najświętszej Maryi Panny i świętego Józefa Oblubieńca | church | -582, -1036 | front on kept skin (`karmelici`) |
| Kościół Zielonoświątkowy | church | -1890, 332 | model from photos (`church_zielonoswiatkowy`, `_build_zielonoswiatkowy`, spec `zielonoswiatkowy.md`), 2026-11-14 |
| Kościół parafialny pw. Dzieciątka Jezus | church | -1825, 980 | model from photos (`church_dzieciatka`, `_build_dzieciatka`, spec `dzieciatka.md`), 2026-11-14 |
| Kościół parafialny pw. Narodzenia Najświętszej Maryi Panny | church | -1969, -976 | model from photos (`church_narodzenia`, `_build_narodzenia`, spec `narodzenia.md`), 2026-11-14 |
| Kościół pw. Matki Boskiej Zwycięskiej | cathedral | 1971, -1373 | model from 16 Commons photos and LoD2 (`church_zwycieska`, `_build_zwycieska`, spec `zwycieska.md`), 2026-11-14: cream-white 1930s church, tall front block with a round window and yellow strips, red nave roof, round apse, domed chapel; no spires |
| Kościół pw. Miłosierdzia Bożego i Świętej Faustyny | church | -2749, -693 | model from photos (`church_miloserdzie`, `_build_miloserdzie`, spec `miloserdzie.md`), 2026-11-14 |
| Kościół pw. Świętego Augustyna | church | -2417, -1176 | model from the description and LoD2 (`church_augustyn`, `_build_augustyn`, spec `augustyn.md`), 2026-11-14 |
| Kościół pw. Świętego Ducha | church | -1020, -1836 | whole model from photos (`church_duch`, `_build_duch`, spec `duch.md`), replacing the 2026-11-01 kit model |
| Kościół pw. Świętego Jacka | church | -1011, -1913 | whole model from photos (`church_jacek`, `_build_jacek`, spec `jacek.md`), replacing the 2026-11-01 kit model |
| Kościół pw. Świętego Krzyża | church | -473, -525 | model on kept skin: baroque facade and towers (`sw_krzyz`) |
| Kościół pw. Świętego Marcina | church | -795, -1584 | whole model from photos (`church_sw_marcin`, `_build_marcin`, spec `marcin.md`), replacing the 2026-11-01 kit model |
| Kościół pw. Świętej Anny | church | -658, -1350 | model, kept skin: portico and tower trim (`sw_anna`, #211 deck people) |
| Kościół pw. Świętych Apostołów Piotra i Pawła | church | -1129, 830 | model from 14 Commons photos and LoD2 (`church_piotr_pawel`, `_build_piotr_pawel`, spec `piotr_pawel.md`), 2026-11-14: sand stucco basilica, front with three arched porches, rose window and two corner towers, drum and green dome over the crossing, rounded apse |
| Kościół Świętego Antoniego Padewskiego | church | -1211, -978 | model from 15 Commons photos and LoD2 (`church_antoniego`, `_build_antoniego`, spec `antoniego.md`), 2026-11-14: white Baroque church, red tile roofs, slate turret with a green double onion, octagonal chapel, cloister wings round the cross square |
| Kościół Świętej Trójcy | church | -855, -511 | model (`trojca`, Zug's rotunda) |
| Kościół Świętej Trójcy na Solcu | church | 1071, 263 | model from photos (`church_trojca_praga`, `_build_trojca_solec`, spec `trojca_solec.md`), 2026-11-14 |
| Kościół św. Brata Alberta i św. Andrzeja Apostoła | church | -1074, -1133 | model from photos (`church_alberta`, `_build_alberta`, spec `alberta.md`), 2026-11-14 |
| Matki Bożej Częstochowskiej | church | 1132, 868 | model from photos (`church_czestochowska`, `_build_czestochowska`, spec `czestochowska.md`), 2026-11-14 |
| Monaster Zaśnięcia Najświętszej Bogurodzicy i św. Jozafata biskupa i męczennika | monastery | -1025, -1518 | model from LoD2 and the street photos (`church_bazylianie`, `_build_bazylianie`, spec `bazylianie.md`), 2026-11-14: the street wing with the church's front, the back wings |
| Parafia Świętej Teresy od Dzieciątka Jezus | church | 370, -579 | model (`teresy`, #225) |
| Siostry Szarytki (Zakład Sióstr Miłosierdzia, Tamka 35; unnamed in OSM) | monastery | 78, -165 | LoD2 mass in its skin plus a model turret (`szarytki`, `_build_szarytki`, spec `szarytki.md`), 2026-11-15 from 11 Commons photos: white ranges, green copper roofs, the onion turret; the dormers are not built |
| Domy Szarytek przy zaułku (two houses of the Sisters of Charity by Zaułek Ku Szarytkom; unnamed in OSM) | religious | 80, -268 | LoD2 mass in a skin (`szarytki_zaulek`, spec `szarytki_zaulek.md`), 2026-11-15: the convent's white plaster and green copper roofs; **provisional, no photo** |
| Dom Prowincjalny Sióstr Elżbietanek (behind Piekarska, over the Podwale gardens) | convent | -834, -1573 | LoD2 mass in its skin plus a model rounded end (`elzbietanki`, `_build_elzbietanki`, spec `elzbietanki.md`), 2026-11-15 from LoD2 only: **provisional, no photo** (F's 12 Piekarska photos show the street fronts, not this range); plaster and tiles are defaults |
| Klasztor przy sanktuarium św. Faustyny (Siostry Matki Bożej Miłosierdzia, Żytnia; three unnamed blocks) | convent | -2740, -685 | LoD2 mass in a skin (`faustyna_klasztor`, spec `faustyna_klasztor.md`), 2026-11-15: the ranges round the shrine in its white plaster and grey roofs; no photo of the ranges themselves |
| Klasztor Reformatów (unnamed monastery by St Anthony's, Senatorska 31) | monastery | -1170, -1001 | model from LoD2 (`church_reformaci_klasztor`, `_build_reformaci_klasztor`, spec `reformaci_klasztor.md`), 2026-11-15: four ranges round a courtyard in the church's white and orange-red tiles; **provisional, no photo** of the friary's own walls |
| Plebania Katedry Polowej (the Field Cathedral's presbytery, Długa 13/15) | presbytery | -1153, -1670 | model from photos and LoD2 (`church_plebania_katedra_polowa`, `_build_plebania_katedra_polowa`, spec `plebania_katedra_polowa.md`), 2026-11-15: a three-storey cream house against the cathedral's north side, the front on Długa; roof colour a default |
| Plebania św. Augustyna (St Augustine's presbytery, Nowolipki) | presbytery | -2410, -1115 | model from LoD2 (`church_plebania_augustyn`, `_build_plebania_augustyn`, spec `plebania_augustyn.md`), 2026-11-15: a two-storey flat-roofed house with a raised middle block; **provisional, no photo** |
| Plebania katedry św. Floriana (St Florian's cathedral presbytery, Floriańska, Praga) | presbytery | 538, -1965 | model from photos and LoD2 (`church_plebania_florian`, `_build_plebania_florian`, spec `plebania_florian.md`), 2026-11-15: a white range on Floriańska over a rusticated ground floor with round-headed windows and a cream wing into the yard; roof colour a default |
| Kaplica przy katedrze św. Floriana (the octagonal chapel at the corner of the close, Floriańska; unnamed in OSM) | chapel | 459, -2000 | model from photos (`church_kaplica_florianska`, `_build_kaplica_florianska`, spec `kaplica_florianska.md`), 2026-11-15: a red brick octagon under a dark slate bell roof with a finial; the door is a default |
| Kaplica przy Łuckiej (the yard chapel behind Łucka 2/4/6; unnamed in OSM) | chapel | -2257, 72 | model from LoD2 (`church_kaplica_lucka`, `_build_kaplica_lucka` with `_flat_chapel`, spec `kaplica_lucka.md`), 2026-11-15: a flat-roofed plastered chapel with tall windows, an arched door and a cross; **provisional, no photo** |
| Kaplica przy Hożej (the yard chapel behind Hoża 55; unnamed in OSM) | chapel | -1009, 1028 | model from LoD2 (`church_kaplica_hoza`, `_build_kaplica_hoza` with `_flat_chapel`, spec `kaplica_hoza.md`), 2026-11-15: a long flat-roofed plastered chapel with tall windows, an arched door to Hoża and a cross; **provisional, no photo** |
| Kłopotowskiego 18 (the church house with the "Okno Życia" window of life, Praga; unnamed in OSM) | religious | 553, -1799 | model from photos and LoD2 (`church_klopotowskiego_18`, `_build_klopotowskiego_18`, spec `klopotowskiego_18.md`), 2026-11-15: four storeys of white plaster over a cream rusticated ground floor, the door in a grey surround, the window of life and its balcony; roof and yard defaults |
| The monastery block beside Our Lady of Victory (Kamionek; unnamed in OSM) | monastery | 2034, -1360 | model from LoD2 (`church_zwycieska_klasztor`, `_build_zwycieska_klasztor`, spec `zwycieska_klasztor.md`), 2026-11-15: a five-storey cream range under red tiles; **provisional, no photo** |
| Dom zakonny na Żytniej (the convent range on Żytnia's south side by Wolność; unnamed in OSM) | religious | -2679, -736 | model from photos and LoD2 (`church_zytnia_dom_zakonny`, `_build_zytnia_dom_zakonny`, spec `zytnia_dom_zakonny.md`), 2026-11-15: two storeys of cream plaster on a brick plinth, rusticated ground floor with barred windows, grey gable roof |
| Dom zakonny na Żytniej, skrzydło (the long range behind it inside the block; unnamed in OSM) | religious | -2647, -705 | model from LoD2 (`church_zytnia_dom_zakonny_tyl`, `_build_zytnia_dom_zakonny_tyl`, spec `zytnia_dom_zakonny_tyl.md`), 2026-11-15: the street range's walls under a low grey roof; **provisional, no photo** |
| Dom Sióstr Uczennic Boskiego Mistrza (the Sister Disciples of the Divine Master, Żytnia, Wola) | convent | -2894, -661 | model from photos and LoD2 (`church_uczennice_boskiego_mistrza`, `_build_uczennice_boskiego_mistrza`, spec `uczennice_boskiego_mistrza.md`), 2026-11-15: five storeys of red brick with cream window strips and the chapel's raised block |
| Dom Generalny Zgromadzenia Sióstr Sług Jezusa (the Servants of Jesus' generalate, Sewerynów) | convent | -200, -518 | model from photos and LoD2 (`church_sluzki_dom_generalny`, `_build_sluzki_dom_generalny`, spec `sluzki_dom_generalny.md`), 2026-11-15: a six-storey ochre house on its street with a wing into the yard |
| Siostry Matki Bożej Miłosierdzia, the range on Żytnia (unnamed `religious` in OSM, Żytnia 3/9) | convent | -2790, -696 | model from photos and LoD2 (`church_siostry_milosierdzia_zytnia`, `_build_siostry_milosierdzia_zytnia`, spec `siostry_milosierdzia_zytnia.md`), 2026-11-15: red brick with white window strips and the white portal; the convent's other buildings round the shrine (4468, 4469, 4473, 10477, 10480) follow |
| Sala św. Faustyny | chapel | -2792, 1574 | model from one Commons photo and the OSM outline (`church_sala_faustyny`, `_build_sala_faustyny`, spec `sala_faustyny.md`), 2026-11-14: red brick hall, three steep gabled bays, the round-arched porch |
| Synagoga Nożyków | synagogue | -1565, -229 | whole model from photos (`_build_nozyk`, spec `nozyk.md`), 2026-11-14; the kit's front faced east |
| Zgromadzenie Sióstr Franciszkanek Rodziny Maryi | religious | -2617, -739 | model from LoD2 and two photos (`church_rodziny_maryi`, `_build_rodziny_maryi`, spec `rodziny_maryi.md`), 2026-11-14: the long banded peach house, its blind windows and the taller middle block |

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
