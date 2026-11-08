# City inventory: every characteristic place, street by street

F asked (2026-11-02) for one list of every place in the map box that can make the city feel
real: landmarks, tenements (kamienice), monuments and sculptures, distinctive houses, museums,
popular bars, metro stations, shopping centres, upscale flats, skyscrapers and office buildings.
Sorted from the most valuable to the least, each marked done, not done, or done with the new
photo approach. **Part 1** is the ranked list (keep it current: a thread that lands an item
changes its status here in the same PR, like ROADMAP's v1.0 checklist). **Part 2** is the same
places street by street, regenerated from the map data with `python3 -I tools/city_inventory.py`
(it reads Part 1's statuses, so edit Part 1 and re-run). docs/LANDMARKS.md keeps the build detail
of each model; this file only says what exists and what is next.
The wiki's Model progress page (wiki.aroundwarsaw.app/models/) is generated from Part 1. A row counts as
*researching* when its Next cell says "photos gathered" (or its status is ⏳): write that when the Mac's
`refs/<slug>/` and REPORT exist, before the model is built.

## Why some places were rebuilt "outline only"

Most models from 2026-10-31 to 2026-11-02 were built by cloud threads. The cloud cannot open
Wikimedia Commons, GUGiK or Geoportal (403), and the photo library `refs/` lives on F's Mac, so
those threads had only the OpenStreetMap outline, the GUGiK LoD2 heights in the map and published
text. They built what the outline allows and marked every guessed value *(photo check)*: about
50 such checks are parked in docs/QUESTIONS.md. The places that look right (the Palace, the
Rotunda, the Eastern Wall stores, MSN, Złota 44, Warsaw Spire, Dom pod Orłami) are the ones built
from F's own photos or checked side by side with photos on the Mac. **Rule from now on:** a model
of a tier S or A place starts from photos (F's, or `refs/` on the Mac); a cloud thread without
photos asks the coordinator for them or for Mac folder access first, and does not build blind.

## The new approach (the MSN recipe)

The model-from-photos skill (`.claude/skills/model-from-photos`), as used for Muzeum Sztuki
Nowoczesnej, Złota 44 and Warsaw Spire: (1) photos: F's own or `refs/<slug>/` (several angles,
day and night) plus the GUGiK orthophoto for the roof; (2) all data: the OSM parts and outline,
LoD2 heights, published facts (architect's pages, news, listings); (3) an Opus spec in
`docs/landmarks/specs/<slug>.md` with a parts table, every value tied to a photo or a source;
(4) `object-modeler` builds within a triangle budget; (5) `art-director` scores it side by side
against the photos; (6) F's look on the Mac or the phone closes it.

## Status legend

| Mark | Meaning |
| --- | --- |
| ★ | **Photo build** (the new approach): built from F's photos or checked side by side against photos on the Mac |
| ◐ | **Outline build**: own model from the OSM outline, LoD2 and published facts, no photo yet; Mac photo check parked. Next step: photo re-pass |
| ○ | **Dress only**: colour skin, the shared tower builder, a neon sign, a card or street dress; no model of its own |
| ⏳ | In progress in an open PR or a running thread (do not start a second thread) |
| ✗ | **Not done**: a plain grey LoD2/OSM block, or not in the game at all |

Tiers: **S** the city's faces (postcards, skyline, the first ten minutes); **A** iconic, seen
often, known to every visitor; **B** characteristic, known to locals, gives a street its identity;
**C** texture (named tenements, offices, embassies, small institutions) in Part 2 only.

<!-- counts:start -->
**Counts** (Part 1, 154 ranked rows): ★ 51 photo builds · ◐ 48 outline builds · ○ 21 dress only · ⏳ 2 in progress · ✗ 32 not done. Part 2 adds 541 named outlines (tier C): 19 with a model of their own, 77 dressed or named in the game, 445 plain blocks. From OpenStreetMap points (the monuments and plaques stand as generic pieces from tools/bake_monuments.py since 2026-11-02, the rest are not baked): 216 monuments and sculptures, 26 murals, 267 bars and clubs, 102 museums and galleries, 38 theatres and cinemas, 4 malls, 34 hotels, 688 plaques and memorial stones (the named office buildings are already outlines above).
<!-- counts:end -->

## Part 1. The ranked list

### Tier S: the city's faces

| # | Place | Street | Kind | Status | Next |
| --- | --- | --- | --- | --- | --- |
| 1 | Pałac Kultury i Nauki | Plac Defilad / Marszałkowska | landmark | ★ | stone colour and the 30th-floor terrace (QUESTIONS) |
| 2 | Rotunda (OSM: Rotunda PKO) | Marszałkowska (Rondo Dmowskiego) | landmark pavilion | ★ | none |
| 3 | Domy Towarowe Centrum: Junior, Sawa, Wars | Marszałkowska | department stores | ★ | Pasaż Wiecha and its pavilions behind them built 2026-11-02 (site `wiecha`); phone look; F's look-check answers applied 2026-11-03 (BACKLOG "Landmark look-check fixes"). |
| 4 | Muzeum Sztuki Nowoczesnej | Marszałkowska (Plac Defilad) | museum | ★ | R8: the ribbon and the roofline |
| 5 | Złota 44 | Złota | upscale flats, skyscraper | ★ | Mac look check |
| 6 | Warsaw Spire (with Spire B, Spire C and the fountain plaza) | Plac Europejski | office skyscraper | ★ | rebuilt from F's ten photos 2026-11-06 (LED ticker, plaza water); phone look |
| 7 | Varso Tower (with Varso I, Varso II) | Chmielna | office skyscraper | ◐ | photo re-pass of the crown, the spire and the two low towers |
| 8 | Złote Tarasy (with Lumen, Skylight) | Złota / Aleja Jana Pawła II | shopping centre, offices | ◐ | photo re-pass: the wave, Lumen's ribbons, Skylight's crown |
| 9 | Warszawa Centralna | Aleje Jerozolimskie | station | ★ | the wings' walls (QUESTIONS) |
| 10 | Zamek Królewski (OSM: Wieża Zegarowa) | Plac Zamkowy | royal castle | ⏳ | PR #299 (Clock Tower, Vistula front, Kubicki's Arcades); then a photo check |
| 11 | Kolumna Zygmunta | Plac Zamkowy | monument | ◐ | photo-checked 2026-11-06 (zygmunt.md): granite, bronze ring and capital, four steps; cross/sabre sides still need an in-game look |
| 12 | Rynek Starego Miasta and its Syrenka | Rynek Starego Miasta | square, statue | ◐ | photo re-pass: paving, umbrellas, the statue's pose; the north and west fronts' gables |
| 13 | Stadion Narodowy | Aleja Zieleniecka | stadium | ★ | the bank's grass against the orthophoto |
| 14 | Most Poniatowskiego (towers and deck) | Aleja Poniatowskiego | bridge | ★ | built 2026-11-02 from `refs/poniatowski/` (30 Commons photos, four orthos), spec `poniatowski.md`; the Powiśle viaduct's arcade and the north stairs 2026-11-03, rebuilt the same day as open ribs and struts with bars in the closed bays (F's answer); F's look on the Mac or the phone |
| 15 | Most Świętokrzyski | Wybrzeże Kościuszkowskie | bridge | ◐ | photo check of the pylon and stays |
| 16 | Centrum Nauki Kopernik and Planetarium (OSM: Planetarium Niebo Kopernika) | Wybrzeże Kościuszkowskie | science centre | ★ | none |
| 17 | Biblioteka Uniwersytecka (BUW) and its roof garden | Dobra | library, garden | ★ | the philosophers and heights (no facade photo yet) |
| 18 | Teatr Wielki and Teatr Narodowy | Plac Teatralny (Moliera, Fredry) | opera, theatre | ◐ | photo re-pass of the colonnade; Teatr Narodowy's wing is ✗ |
| 19 | Grób Nieznanego Żołnierza and Plac Piłsudskiego | Plac Piłsudskiego | monument, square | ◐ | the square's paving, masts and monuments built 2026-11-02 from `refs/pilsudskiego/` (spec `plac_pilsudskiego.md`); the Tomb's photo re-pass from `refs/grob/`; the Saxon Palace site (QUESTIONS) |
| 20 | Muzeum Historii Żydów Polskich Polin and Pomnik Bohaterów Getta | Mordechaja Anielewicza | museum, monument | ★ | built 2026-11-02 from `refs/polin/` (25 Commons photos, the ortho) and LoD2, spec `polin.md`; F's look on the Mac or the phone |
| 21 | Muzeum Powstania Warszawskiego (OSM: Elektrownia Tramwajów Miejskich) | Przyokopowa / Grzybowska | museum | ★ | built 2026-11-02 from `refs/mpw/` (25 Commons photos, the ortho, REPORT/PARTS) and LoD2, spec `mpw.md`: the brick front, the halls, the tower with the Kotwica, the Wall of Remembrance; F's look on the Mac or the phone; F's look-check answers applied 2026-11-03 (BACKLOG "Landmark look-check fixes"). |
| 22 | Pomnik Powstania Warszawskiego | Plac Krasińskich | monument | ★ | built 2026-11-02 from `refs/pomnik_powstania/` (14 Commons photos, the ortho), spec `pomnik_powstania.md`; F's look on the Mac or the phone |
| 23 | Barbakan and the city walls (OSM: Baszta Prochowa) | Nowomiejska / Podwale | fortification | ◐ | Barbakan photo check; the walls and towers along Podwale are ✗ |
| 24 | Archikatedra św. Jana | Świętojańska | cathedral | ◐ | photo check; the tower |
| 25 | Kościół św. Anny | Krakowskie Przedmieście | church | ◐ | photo check: columns, the bell tower |
| 26 | Hotel Bristol and Hotel Europejski | Krakowskie Przedmieście | grand hotels | ★ | photos gathered (`refs/krakowskie/`); Bristol built 2026-11-02 (cream, zinc mansard, the open belvedere on the Karowa corner); Europejski rebuilt 2026-11-03 from F's photos (bow-fronts with column tiers, pedimented bays, plaque, balustrade attic, louvred roof storey, courtyard; spec `europejski.md`); phone look check |
| 27 | Pałac Prezydencki | Krakowskie Przedmieście | palace | ◐ | photo check of the portico and statue |
| 28 | Rondo ONZ towers: Q22, Rondo 1, Cosmopolitan, InterContinental (OSM: InterContinental), Warsaw Trade Tower | Rondo ONZ / Emilii Plater / Twarda | skyscrapers | ○ | **photo build** of each crown and skin (one thread per tower, Q22 and Rondo 1 first) |
| 29 | Hotel Warszawa (the 1934 Prudential) | Plac Powstańców Warszawy | historic skyscraper, hotel | ★ | built 2026-11-02 from `refs/hotel_warszawa/` (Commons photos, the ortho) and LoD2, spec `hotel_warszawa.md`; Mac look check (QUESTIONS); F's look-check answers applied 2026-11-03 (BACKLOG "Landmark look-check fixes"). |
| 30 | Cedet (Dom Towarowy CDT) | Krucza / Aleje Jerozolimskie | department store | ★ | built 2026-11-02 from `refs/cedet/` (Commons photos, the ortho) and LoD2, spec `cedet.md`; F's look check applied 2026-11-03 (wings, 11 m corner, 3.7 m storeys, recessed pavilion, grey-bronze loop) |

### Tier A: iconic, seen often

| # | Place | Street | Kind | Status | Next |
| --- | --- | --- | --- | --- | --- |
| 31 | Pomnik Syreny nad Wisłą (OSM: Syrenka na Powiślu) | Wybrzeże Kościuszkowskie | statue | ◐ | photo check of the plinth |
| 32 | Pomnik Mikołaja Kopernika and Pałac Staszica | Krakowskie Przedmieście | monument, palace | ◐ | photo report staszic.md (2026-11-06): colours fixed; front is an arcade not a portico, dome and statue spot wait on an orientation check (QUESTIONS) |
| 33 | Pomnik Adama Mickiewicza | Krakowskie Przedmieście | monument | ★ | photos gathered (`refs/krakowskie/`); built 2026-11-02 from them, spec `mickiewicz.md`; F's look on the Mac or the phone |
| 34 | Kościół Świętego Krzyża | Krakowskie Przedmieście | church | ◐ | photo check: the helms, the dome |
| 35 | Brama Uniwersytetu Warszawskiego and Pałac Kazimierzowski | Krakowskie Przedmieście | gate, palace | ★ | photos gathered (`refs/krakowskie/`); built 2026-11-02 from them, specs `brama_uw.md`, `kazimierzowski.md`; F's look on the Mac or the phone |
| 36 | Kościół Wizytek, Kościół Karmelitów (OSM: Kościół Wniebowzięcia Najświętszej Maryi) | Krakowskie Przedmieście | churches | ◐ | Karmelici ★: photos gathered (`refs/krakowskie/`); built 2026-11-02 from them, spec `karmelici.md`; Wizytki: photo check |
| 37 | Pałac Potockich, Kordegarda (OSM: Galeria Kordegarda), Pałac Czapskich | Krakowskie Przedmieście | palaces | ★ | photos gathered (`refs/krakowskie/`); built 2026-11-02 from them, Czapski whole, Potocki's gates and colours, the Kordegarda (specs `czapski.md`, `potocki.md`, `kordegarda.md`); F's look on the Mac or the phone |
| 38 | Plac Zamkowy's houses and Mariensztat | Plac Zamkowy / Mariensztat | tenements | ○ | photo re-pass of the gables; Mariensztat's reliefs |
| 39 | Old Town and New Town tenements: Kamienica Pod Bazyliszkiem, Pod Murzynkiem, Fukierowska, Baryczkowska, Pod Okrętem | Rynek Starego Miasta / Freta | tenements | ○ | photo pass per famous house (signs, portals, painted fronts) |
| 40 | Nowy Świat tenements and palaces (Zamoyski, Mikulski, Bürger, Jasiński, Kossakowski) | Nowy Świat | tenements | ◐ | 50 blocks modelled (BACKLOG "Street blocks across the city"); #29 left |
| 41 | Kościół Świętego Aleksandra and Plac Trzech Krzyży | Plac Trzech Krzyży | church, square | ◐ | photo check; the square's houses (Kamienica pod Gryfami) |
| 42 | Sejm and Senat (OSM: Sala posiedzeń Sejmu RP, Senat RP) | Wiejska | parliament | ◐ | photo check; the Senate and the Sejm's office slabs are ✗ |
| 43 | Zamek Ujazdowski | Jazdów (Aleje Ujazdowskie) | castle, art centre | ◐ | photo check |
| 44 | Zachęta | Plac Małachowskiego | gallery | ★ | the back and the roof |
| 45 | Kościół Świętej Trójcy | Plac Małachowskiego | church | ★ | oculi count |
| 46 | Metropolitan | Plac Piłsudskiego | offices | ◐ | photo pass 2026-11-07 (`warsaw-needed-photos`): the seventh storey and plant rooms in silver metal; still to do: the recessed glazed ground floor on round piers, the curved silver roof canopy, a parody sign for the bank on the corner |
| 47 | Muzeum Narodowe and Muzeum Wojska Polskiego's yard | Aleje Jerozolimskie | museum | ◐ | **photo build**: the 1930s front, the tanks and planes in the yard |
| 48 | Dom Partii (OSM: Centrum Bankowo-Finansowe) and Rondo de Gaulle'a's palm | Nowy Świat / Aleje Jerozolimskie | offices, monument | ◐ | photo check |
| 49 | Pawilony za Nowym Światem | Nowy Świat | bar pavilions | ◐ | photo check (neon, string lights) |
| 50 | Plac Konstytucji and MDM | Marszałkowska | socialist-realist square | ◐ | photo re-pass: arcades, reliefs, the candelabras |
| 51 | Kościół Najświętszego Zbawiciela and Plac Zbawiciela | Marszałkowska | church, square | ◐ | photo check: towers, the square's arcades |
| 52 | Rondo Dmowskiego and Patelnia (Metro Centrum) | Marszałkowska | square, metro | ◐ | Mac look check |
| 53 | Hala Mirowska and Hala Gwardii | Plac Mirowski | market halls | ◐ | photo pass 2026-11-07 (`warsaw-needed-photos`): Mirowska's glazed gallery and dark fascia on the east front added; still to do: the big lattice-glazed arch in the gable and the HALA MIROWSKA letters (needs a neon atlas word); Gwardii not yet |
| 54 | Hala Koszyki | Koszykowa | food hall | ◐ | photo check |
| 55 | Elektrownia Powiśle | Dobra | shopping centre in a power station | ◐ | photo check: chimneys |
| 56 | Fabryka Norblina (OSM: Plater, Galwan) | Prosta | shopping and offices | ★ | moved onto its real block, courts, trees and green roofs from the photo report (2026-11-02); facades: photo check (no facade photo of the new halls yet); F's look-check answers applied 2026-11-03 (BACKLOG "Landmark look-check fixes"). |
| 57 | Browary Warszawskie (OSM: Warzelnia, Laboratorium, Willa Schielego) | Grzybowska | shopping and offices | ◐ | Central Garden (22 trees, S path, café clearings) and sedum roofs from the photo report (2026-11-02); facades and the Brama: photo check; F's look-check answers applied 2026-11-03 (BACKLOG "Landmark look-check fixes"). |
| 58 | Westfield Arkadia (Arkadka) | Aleja Jana Pawła II | shopping centre | ★ | rebuilt from F's photos (2026-11-03); left: plaza paving, the playground's rope worm |
| 59 | Forest | Aleja Jana Pawła II | office tower | ★ | F's photos (2026-11-03); Mac look check |
| 60 | Rondo Daszyńskiego towers: Warsaw Unit, Skyliner, The Warsaw HUB, Mennica Legacy Tower, Generation Park Y | Rondo Daszyńskiego / Prosta | office skyscrapers | ★ | rebuilt 2026-11-03 from the Mac's photo reports (`skyliner.md`, `warsaw_unit.md`, `mennica.md`, `gpy.md`, `warsaw_hub.md`): Skyliner's cut roof, fin and black crown (NOSE AGENCY on it), Unit's black crown and strips, flat tops for Mennica, GPY and the HUB, the HUB's hotel tower; second pass 2026-11-06: Unit's taper and gate hall, Mennica's column arcade, GPY's black patches and wing terraces, the HUB's parapets and skylight; left: Mennica's plaza and west front |
| 61 | Wola towers: The Bridge, Generation Park X and Z, Atlas Tower, Pekao Tower, Warsaw Towers | Grzybowska / Aleje Jerozolimskie / Sienna | office skyscrapers | ◐ | The Bridge photo-built from F's photos with Grzybowska 77 (2026-11-06, spec bridge.md); Atlas is the table's; Pekao Tower and Warsaw Towers ✗; photo build |
| 62 | Centrum LIM (Marriott) and Novotel | Aleje Jerozolimskie / Marszałkowska | hotel towers | ★ | Novotel rebuilt from F's five photos (2026-11-07, `novotel.md`); LIM's podium rebuilt from F's night photos 2026-11-06 (spec `lim-podium.md`: panel bands, gallery, arcade, parody signs, LED screens); LIM's lit cells |
| 63 | Błękitny Wieżowiec and Plac Bankowy | Plac Bankowy | skyscraper, square | ○ | photo check of the glass |
| 64 | Plac Bankowy's palaces: Ratusz (OSM: Urząd Miasta Stołecznego Warszawy), Mazowiecki Urząd Wojewódzki, Gmach Giełdy i Banku Polskiego, Arsenał | Plac Bankowy / Długa | palaces | ★ | photo build 2026-11-02 (spec `bankowy.md`): the Ratusz's colonnaded wings and giant portico, the Bank Polski's rounded corner, drum and green dome, cream walls under copper; left: the Voivodeship wing's own front, the Arsenał |
| 65 | Pomnik Juliusza Słowackiego and Pomnik Stefana Starzyńskiego (OSM: Juliusz Słowacki, Stefan Starzyński) | Plac Bankowy | monuments | ★ | built 2026-11-02 from `refs/slowacki/` and `refs/starzynski/` (Commons photos, the ortho, reports in docs/landmarks/photo-reports/): sites `slowacki` (the platform, pillar, poet in his cloak, two-lantern lamps) and `starzynski` (the mayor sinking into the faceted bronze armchair on its granite block); F's look on the Mac or the phone |
| 66 | Pomnik Bohaterów Warszawy (Nike) (OSM: Warszawska Nike) | Aleja Solidarności | monument | ★ | built 2026-11-02 from `refs/nike/` (4 Commons photos, the ortho): site `nike`, the 9 m granite pylon with its inscription and the lunging bronze Nike with sword and flying cloak; which way she faces is the photos' best guess (north-east), F's look on the Mac |
| 67 | Pomnik Małego Powstańca and Pomnik Jana Kilińskiego (OSM: Mały Powstaniec, Jan Kiliński) | Podwale | monuments | ★ | built 2026-11-02 from `refs/maly_powstaniec/` and `refs/kilinski/`: sites `maly_powstaniec` (the boy in the big helmet on his post, the brick terrace with railing, flowers and candles) and `kilinski` (the dark pedestal, the striding shoemaker with his sabre raised); F's look on the Mac |
| 68 | Pomnik Józefa Piłsudskiego, the Smolensk monuments, Pomnik Lecha Kaczyńskiego | Plac Piłsudskiego | monuments | ★ | built 2026-11-02 from `refs/pilsudskiego/` (spec `plac_pilsudskiego.md`; Kaczyński on his mapped pedestal, Piłsudski at OSM's spot); F's look on the Mac or the phone |
| 69 | Pomnik Poległym i Pomordowanym na Wschodzie (OSM: Poległym i Pomordowanym na Wschodzie) | Muranowska | monument | ★ | built 2026-11-02 from `refs/pomnik_wschod/` (4 Commons photos, the ortho): site `pomnik_wschod`, the flatcar of crosses (with a matzevah and a Muslim tombstone) at the east end of 41 bronze sleepers on the field-stone mound in the median; F's look on the Mac |
| 70 | Umschlagplatz memorial | Stawki | memorial | ★ | built 2026-11-02 from `refs/umschlagplatz/` (2 Commons photos, the ortho): site `umschlagplatz`, the open marble enclosure with the black-crowned gate and the black band, a quiet card; F's look on the Mac |
| 71 | Warszawa Śródmieście, Ochota, Powiśle, Stadion stations | Aleje Jerozolimskie / Wybrzeże Kościuszkowskie | stations | ★ | Śródmieście and Stadion still ◐ (photo check) |
| 72 | Dworzec Gdański and its metro (OSM: Dworzec Warszawa Gdańska) | Słomińskiego | station | ✗ | railway S3d (Mac photos first) |
| 73 | Warszawa Wschodnia | Lubelska | station | ◐ | built 2026-11-03 from the Mac photo report (site `wschodnia`, spec `wschodnia.md`): F's look on the Mac or the phone; F's look-check answers applied 2026-11-03 (BACKLOG "Landmark look-check fixes"). |
| 74 | Metro stations: Centrum, Świętokrzyska, Ratusz-Arsenał, Politechnika, Rondo ONZ, Rondo Daszyńskiego, Nowy Świat-Uniwersytet, Centrum Nauki Kopernik, Stadion Narodowy, Dworzec Gdański | (84 entrances) | metro | ◐ | each station has its own pavilion from photos (2026-11-07): Centrum tubes, Świętokrzyska and Rondo ONZ tents, Stadion/Kopernik/Gdański glass crystals, Nowy Świat violet box; Rondo Daszyńskiego in PR #479; ✗ Politechnika, Centrum stairwells, passage mouths (shoot list) |
| 75 | Narodowy Bank Polski | Świętokrzyska | bank | ✗ | photo build of the 1970s stone block |
| 76 | Poczta Główna | Świętokrzyska | post office | ★ | built 2026-11-03 from `refs/poczta/` (the Mac photo report) and LoD2, spec `poczta.md`: the kept mass in salmon plaster, the corner dome at Jasna, the six-column entrance under the red POCZTA band, the glazed hall; F's look on the Mac or the phone; F's look-check answers applied 2026-11-03 (BACKLOG "Landmark look-check fixes"). |
| 77 | Filharmonia Narodowa | Jasna / Sienkiewicza | concert hall | ★ | photo build 2026-11-02 (spec `filharmonia.md`): the Jasna colonnade, composers on the sills, the FN neon |
| 78 | PAST-a | Zielna | historic telephone tower | ★ | built 2026-11-03 from `refs/pasta/` (the Mac photo report), spec `pasta.md`: the 51 m tower, its arched loggia and merlons, the gilt anchor, the banners and the Uprising plaque; F's look on the Mac or the phone; F's look-check answers applied 2026-11-03 (BACKLOG "Landmark look-check fixes"). |
| 79 | Pałac Krasińskich and Ogród Krasińskich | Plac Krasińskich | palace, park | ★ | built 2026-11-02 from `refs/krasinski/` (17 Commons photos, the ortho) and LoD2, spec `krasinski.md`; the park's details are in; F's look on the Mac or the phone |
| 80 | Vitkac | Bracka | luxury department store | ★ | built 2026-11-03 from `refs/vitkac/` (the photo report) and the OSM outline, site `vitkac`, spec `vitkac.md`, as VIPKAC; F's look on the Mac or the phone |
| 81 | Dom Towarowy Braci Jabłkowskich | Bracka | historic department store | ★ | built 2026-11-03 from `refs/jablkowskich/` (5 photos) and the OSM outline, site `jablkowscy`, spec `jablkowscy.md`; the stained glass inside is not built; F's look on the Mac or the phone |
| 82 | Sheraton Grand Warsaw | Wiejska / Plac Trzech Krzyży | hotel | ★ | built 2026-11-03 from `refs/sheraton/` (3 photos) and the OSM outline and parts, site `sheraton`, spec `sheraton.md`, as SZERATON; the forecourt pavilion is not built; F's look on the Mac or the phone |
| 83 | Teatr Polski and Teatr Powszechny | Karasia / Zamoyskiego | theatres | ★ | Teatr Polski photo build 2026-11-02 (spec `teatr_polski.md`): the Karasia front with its drums, oculi and balcony; Teatr Powszechny ✗ |
| 84 | Bazylika Katedralna Świętego Michała Archanioła i Świętego Floriana Męczennika | Floriańska | Praga cathedral | ★ | photo build 2026-11-02 (site `florian`, spec florian.md): Mac look check of the front's direction and the statue's spot |
| 85 | Koneser and Ząbkowska's tenements | Ząbkowska | vodka works, tenements | ✗ | off the map: Koneser (1426, -2355) lies in the box's cut north-east corner (z < -2045); report on the Mac, waits for the map to grow (QUESTIONS) |
| 86 | Bazar Różyckiego | Targowa | bazaar | ★ | photo build 2026-11-02 (site `bazar`, spec bazar.md): the gate on Targowa waits for a photo; F's look-check answers applied 2026-11-03 (BACKLOG "Landmark look-check fixes"). |
| 87 | Park Praski's bear enclosure (Wybieg dla niedźwiedzi) | Aleja Solidarności | park | ✗ | the rock enclosure and the bears, a card |
| 88 | Multimedialny Park Fontann | Wybrzeże Gdańskie | fountains | ✗ | off the map: the park (-868, -2208) lies in the box's cut north-east corner (z < -2045); report on the Mac, waits for the map to grow (QUESTIONS) |
| 89 | Hotel Polonia Palace, Radisson Blu Sobieski (Radysław Blu) | Aleje Jerozolimskie / Plac Zawiszy | hotels | ◐ | photo check |
| 90 | Plac Defilad's pavilions: Cepelia, Zodiak, Scena Relax (OSM: Pawilon Cepelii) | Marszałkowska | modernist pavilions | ◐ | photo check |

### Tier B: characteristic, gives a street its identity

| # | Place | Street | Kind | Status | Next |
| --- | --- | --- | --- | --- | --- |
| 91 | Bars and clubs with parody names: Lusterko, Smoła, Jasna 0, Lombard, Miłość Hipoteczna, 1499 M2, Plan C, Apteczka, Przegryzki Zagryzki, Kasa Biletowa, Żwir, Bar Pyzowy, Hocki Bloki | Aleje Jerozolimskie, Smolna, Jasna, Mazowiecka, Kredytowa, Emilii Plater, Plac Zbawiciela, Nowy Świat, Kruczkowskiego | bars, clubs | ○ | neon fascias are in; queues at night and the pavilions of Smolna 38 and Kasa Biletowa need photos |
| 92 | Level 26 | Aleje Jerozolimskie (Atlas Tower) | rooftop club | ◐ | photo check |
| 93 | The river barges and the marina (Wieczorek, Biała Barka, Marinka, Kaskadka) | Wybrzeże Kościuszkowskie | bar barges | ◐ | photo check; boulevards' pavilions in PR #310 |
| 94 | Bulwary Wiślane: Schodki, the pavilions, the containers | Wybrzeże Kościuszkowskie | promenade, bars | ⏳ | PR #310 |
| 95 | Milk bars: Bar Prasowy (Marszałkowska), Bar Familijny (Nowy Świat), Bar Bambino (Krucza), Bar Pod Barbakanem (Mostowa) | Marszałkowska / Nowy Świat / Krucza / Mostowa | milk bars | ✗ | parody names and fascias, a lunch queue |
| 96 | Plan B's corner, Plac Zbawiciela's café row | Plac Zbawiciela | bars | ○ | the summer crowd on the pavement (crowds.gd) |
| 97 | Kawiarnia and bar street of Chmielna, Mokotowska, Hoża, Poznańska | Chmielna / Mokotowska / Poznańska | street of bars | ○ | more parody fascias and terraces per block |
| 98 | Kina: Muranów, Atlantic, Luna, Kultura, Elektronik, Femina, Kinoteka, Iluzjon (south of the box) | Andersa / Chmielna / Marszałkowska / Krakowskie Przedmieście / Aleja Solidarności | cinemas | ◐ | Kino Muranów a photo build (2026-11-07, F's photos); the others marquee signs (Amondo none yet); Atlantic and Amondo wait for F's photos; evening queues |
| 99 | Pałac Paca, Pałac Branickich (Miodowa), Pałac Prymasowski, Pałac Blanka, Pałac Jabłonowskich | Miodowa / Senatorska | palaces | ◐ | 2026-11-07 from F's photos (spec `miodowa.md`): Branickich front modelled; Paca, Młodziejowskiego, Szaniawskich, Chodkiewiczów, Arcybiskupi and Collegium Nobilium in photo-read skins. Left: Młodziejowskiego's pediment block, Paca's gate court, Nobilium's tower block; Prymasowski and Blanka (Senatorska) |
| 100 | Katedra polowa, the Cerkiew, Kapucyni (Miodowa churches) | Miodowa | churches | ◐ | church kit; photo check |
| 101 | Synagoga Nożyków and Próżna's pre-war tenements (Kamienica Zalmana Nożyka, Kamienica Wolanowskiego) | Próżna / Twarda | synagogue, tenements | ◐ | the synagogue is the church kit's; Próżna's facades ✗ (photo build) |
| 102 | Plac Grzybowski and Kościół Wszystkich Świętych | Plac Grzybowski | square, church | ◐ | photo-checked 2026-11-06 (wszystkich.md): spired towers, arcade galleries, crossing drum, sandy stone; the square's planter wall and bollards open |
| 103 | Dom pod Orłami and Skwer Linearny na Złotej | Jasna / Złota | historic office, new park | ★ | Mac look check |
| 104 | Hotel Wiktoria (Sofitel Victoria) and Królewska (OSM: Sofitel Victoria) | Królewska | hotel | ◐ | photo check |
| 105 | Ministerstwo Finansów | Świętokrzyska | ministry | ◐ | photo check |
| 106 | Saski Crescent, Saski Park, Senator | Królewska / Bielańska | offices | ✗ | photo build of the curved glass on the Saxon Garden |
| 107 | Gmach Główny Politechniki Warszawskiej (OSM: Gmach Główny PW) | Noakowskiego / Plac Politechniki | university | ✗ | **photo build**: the courtyard hall's front and the dome |
| 108 | Uniwersytet: Auditorium Maximum, Stary BUW, Biblioteka Królewska | Krakowskie Przedmieście | university | ✗ | photo pass of the campus |
| 109 | Pałac Pod Blachą and Biblioteka Królewska | Plac Zamkowy / Wybrzeże Gdańskie | palace | ✗ | with the Castle (after PR #299) |
| 110 | Zamek Ostrogskich and the Chopin Institute | Tamka | palace | ◐ | photo check |
| 111 | Piano House, Cube House, Hortus, Moderna, Dobra and Tamka tenements | Topiel / Leszczyńska / Drewniana / Zajęcza / Dobra / Tamka | upscale flats, tenements | ◐ | photo check |
| 112 | Kamienica Pod Gigantami, Pałac Pod Karczochem, Kamienica Ławrynowicza and Aleje Ujazdowskie's villas (OSM: Pałacyk Rembielińskiego) | Aleje Ujazdowskie | tenements, villas | ✗ | Aleje Ujazdowskie street pass from photos |
| 113 | Pomnik Ronalda Reagana, Pomnik Romana Dmowskiego (Plac Na Rozdrożu) | Aleje Ujazdowskie | monuments | ○ | a generic stand-in from OSM since 2026-11-02 (tools/bake_monuments.py); build from photos |
| 114 | Pomnik Polskiego Państwa Podziemnego i Armii Krajowej, Pomnik Wincentego Witosa, Pomnik Ignacego Daszyńskiego | Wiejska | monuments | ○ | a generic stand-in from OSM since 2026-11-02 (tools/bake_monuments.py); build from photos, with the Sejm pass |
| 115 | Pomnik Marii Skłodowskiej-Curie | Kościelna | statue | ○ | a generic stand-in from OSM since 2026-11-02 (tools/bake_monuments.py); build from photos |
| 116 | Pomnik Sapera | Czerniakowska | monument | ○ | a generic stand-in from OSM since 2026-11-02 (tools/bake_monuments.py); build from photos |
| 117 | Pomnik Kardynała Wyszyńskiego, Pomnik Bolesława Prusa | Krakowskie Przedmieście | monuments | ◐ | photo check |
| 118 | Kamienica Wedla | Szpitalna | tenement, chocolate shop | ✗ | photo build of the corner and its sign (parody) |
| 119 | Kamienica pod Gryfami, Kamienica Johna | Plac Trzech Krzyży / Krakowskie Przedmieście | tenements | ✗ | photo pass |
| 120 | Kamienica pod Zegarem and Chłodna's footbridge memorial (Kładka) | Chłodna | tenement, memorial | ✗ | the clock, the Kładka light sculpture |
| 121 | Hotel Saski, Pasaż Muranów, the Muranów estate | Plac Bankowy / Andersa | hotel, 1950s estate | ✗ | Muranów's rubble-brick blocks as a street dress |
| 122 | Osiedle Za Żelazną Bramą | Plac Żelaznej Bramy | 1960s estate | ◐ | photo check |
| 123 | Aleja Jana Pawła II's blocks and Kaskada | Aleja Jana Pawła II | 1950s blocks, offices | ○ | block-by-block pass from photos |
| 124 | Babka Tower, Atrium 2, Intraco Prime, North Gate | Aleja Jana Pawła II / Stawki / Bonifraterska | offices, flats | ✗ | photo build (Babka is the north's tallest) |
| 125 | Equator, Equator II, Brama Zachodnia, Proximo I and II, Crown Square, Prosta Office Center | Aleje Jerozolimskie / Prosta / Przyokopowa | office buildings | ◐ | Equator, Equator II, Brama Zachodnia skinned by street photo 2026-11-06 (BLUZOFT sign); Proximo, Crown, Prosta Office Center left |
| 126 | Warsaw Corporate Centre, Centrum Giełdowe, Mysia 3, Liberty Corner, Nautilus, Ethos | Emilii Plater / Książęca / Mysia / Nowogrodzka | office buildings | ✗ | office pass |
| 127 | Żyletkowiec, Dom Słowa Polskiego, Dom Chłopa, Smyk's corner | Wspólna / Miedziana / Plac Powstańców / Krucza | modernist landmarks | ✗ | **high priority**: the modernism set (docs/design/modernism-collection.md M4, M5, M12; Smyk is Cedet, #30); photo build, Żyletkowiec first |
| 128 | Atelier Residence, Rezydencja Foksal, Apartamenty Flare, Solec Residence, Złota Chmielna | Bagno / Kopernika / Grzybowska / Solec / Złota | upscale flats | ✗ | photo pass (Młotek moved to #147, the modernism set) |
| 129 | Platinum Towers, Łucka City, Ilmet, Central Tower, Spektrum, PZU, JM Tower, Chałubińskiego 8, Westynka, Chilton | Grzybowska / Łucka / Jana Pawła II / Jerozolimskie / Twarda / Chałubińskiego | skyscrapers | ○ | crowns by photo (tower table) |
| 130 | Torwar | Łazienkowska | arena | ✗ | photo build |
| 131 | Stadion Leguminy | Łazienkowska | stadium | ◐ | photo check |
| 132 | Gdański Business Center | Inflancka | offices | ◐ | photo check |
| 133 | WTS DESKA | Wioślarska | tennis club | ◐ | photo check |
| 134 | Klif | Okopowa | shopping centre | ✗ | plain glass mall, low priority |
| 135 | Galeria Wileńska and Dworzec Wileński | Targowa | shopping centre, metro | ✗ | outside the box today (the outside corner); only if the map grows |
| 136 | Skwer Hoovera's pavilions and the Christmas lights | Krakowskie Przedmieście | square | ✗ | the winter dress |
| 137 | Ogród Saski, Ogród Krasińskich, Park Ujazdowski | Marszałkowska / Świętojerska / Aleje Ujazdowskie | parks | ○ | park details in; the Saxon Garden's fountain and Wodozbiór (OSM: Wodozbiór "Świątynia Vesty") as models ✗ |
| 138 | Muzeum Karykatury, Kinomuzeum, Muzeum Niepodległości, Muzeum Wodociągów | Krakowskie Przedmieście / Marszałkowska / Aleja Solidarności / Nowogrodzka | small museums | ✗ | card and sign each |
| 139 | Warszawska Opera Kameralna, Teatr WARSawy, Pałac Ślubów | Aleja Solidarności / Freta / Rynek | culture | ✗ | card and sign each |
| 140 | Stara Prochownia, Collegium Nobilium, Klasztor Ojców Dominikanów (Kościół pw. Świętego Jacka) | Boleść / Miodowa / Freta | historic | ◐ | St Hyacinth is the church kit's; the others ✗ |
| 141 | Talking benches (ławeczki): Ławeczka Jana Karskiego, Ławeczka Jana Nowaka-Jeziorańskiego, Ławeczka księdza Twardowskiego, Ławeczka Henryka Sławika i Józsefa Antalla, Ławeczka Studenta, Ławeczka Jerzego Janickiego, Ławeczka Wandy Tazbir | (see Part 2 per street) | bronze benches | ○ | one shared bronze bench with a sitting figure at each OSM spot (tools/bake_monuments.py, 2026-11-02); a card each left |
| 142 | Monuments OSM adds: Janusz Korczak, Witold Pilecki, Napoleon Bonaparte, Monte Cassino, Pomnik Ofiar Rzezi Woli, Kobietom Powstania Warszawskiego, Jan Rodowicz "Anoda", Wojciech Korfanty, Ignacy Jan Paderewski, Wojciech Bogusławski, Stanisław Moniuszko, Kotwica z żaglowca szkolnego "Lwów" | (see Part 2 per street) | monuments | ○ | a generic statue, bust, stele or stone at each OSM spot (tools/bake_monuments.py, 2026-11-02: 75 statues, 32 busts, 68 steles, 66 stones, 26 sculptures, Ogród Saski's 19 allegories at their real spots); photo builds one by one; Moniuszko and Bogusławski stand at Teatr Wielki |
| 143 | Murals (26 named in OSM) | (see Part 2) | murals | ✗ | original paintings on the mapped walls (a decal per wall), never copies of the real artworks |
| 144 | Plaques and memorial stones (about 690: Tchorek's Uprising plaques, stones, steles) | (every street) | plaques | ○ | a sandstone Tchorek-style plaque with a cross, a ribbon and two candles on the nearest drawn wall at 520 OSM plaque points (tools/bake_monuments.py, 2026-11-02; 49 with no wall within 12 m left out); the count per street is in Part 2 |
| 145 | Warszawa Śródmieście WKD and Warszawa Ochota WKD (the WKD commuter line's stops) | Aleje Jerozolimskie / Plac Zawiszy | stations | ★ | built 2026-11-02 from `refs/wkd_srodmiescie/` and `refs/wkd_ochota/` (Commons photos, the ortho; reports in docs/landmarks/photo-reports/), railway S3c-e; F's look on the Mac or the phone (the propellers' twist, Ochota's stair) |
| 146 | Gmach Banku Gospodarstwa Krajowego | Aleje Jerozolimskie / Nowy Świat | bank, 1928-31 | ★ | built 2026-11-03 from `refs/bgk/` (8 Commons photos, the ortho; report `docs/landmarks/photo-reports/bgk.md`) and the OSM outline, site `bgk`, spec `bgk.md`; the roof signs left out; F's look on the Mac or the phone |

### Warsaw modernism and brutalism (F, 2026-11-03, high priority)

F: "I love modernism". The plan, the ranking (M1-M17) and the collect-them-all quest "Betonowy album"
are in docs/design/modernism-collection.md. Every row is a photo build from the Mac's `refs/<slug>/`
and REPORT. The set also counts rows already here: Rotunda (2), Domy Towarowe Centrum (3), Centralna
(9), Hotel Warszawa (29), Cedet (30), LIM and Novotel/Forum (62), the stations (71), BGK (146, built
2026-11-03), and the re-passes of 42, 47, 73, 90, 104, plus NBP (75), Torwar (130) and 127's modernist
landmarks.

| # | Place | Street | Kind | Status | Next |
| --- | --- | --- | --- | --- | --- |
| 147 | Młotek (Smolna 8, 1976, Bogusławski and Gniewiewski, 20 storeys, 66 m) | Smolna | brutalist flats | ★ | built 2026-11-05 (site `mlotek`, report `mlotek`): F's look; the north face wants a street photo |
| 148 | Kozia 9 (1974-76, Kuźmienko and Sembrat) | Kozia / Moliera | modernist flats | ★ | built 2026-11-05 (site `kozia9`, report `kozia9`, only 2 photos of the block): F's look; street photos of the Moliera side would help |
| 149 | Karowa 18a (1978, Dąbrowski, Kuźmienko, Nowak, Sembrat) | Karowa | modernist flats | ★ | built 2026-11-05 (site `karowa18a`, report `karowa18a`, 12 photos): F's look; the rear terraces are not built |
| 150 | Drapacz chmur na Kopernika (the Helvetia hotel, 1923-28, Antoni Jawornicki) | Kopernika / Sewerynów | interwar tower | ✗ | M7: photo build (`refs/kopernika_helvetia/`): the central tower, Art Deco detail |
| 151 | Osiedle Za Żelazną Bramą (1965-72, Czyż, Furman, Skopiński, Józefowicz) | Plac Mirowski / Grzybowska / Twarda | slab estate | ✗ | M8: one shared slab kit from photos (`refs/zelazna_brama/`), one material, draw calls per sector |
| 152 | Ministerstwo Komunikacji (today the Ministry of Infrastructure) | Chałubińskiego | interwar ministry | ✗ | M11: photo build (`refs/min_komunikacji/`) |
| 153 | Pawilon Emilia (1970, taken down in the 2010s) | Emilii Plater | lost pavilion | ✗ | a KASETA then card with its ghost, not a model (the album's lost slide) |
| 154 | Towarowa 22 (superkwartał on the Dom Słowa Polskiego site) | Towarowa / Pańska / Miedziana | new city quarter | ◐ | built 2026-11-03 as finished, from F's masterplan renders and photos (spec `towarowa22.md`): the tower row, the tanks block, Gutenberga, the printing hall's yellow frame, Pawilon DSP, Park Słowa, a drone port and the gilded last crane; the Office House, M7 and the octagon stay the map's; photo pass once the towers stand |
| 155 | Prosta 32, Prosta 28 and Łucka City (Łucka 15) | Prosta / Łucka | offices and residential tower | ★ | built 2026-11-06 from F's photos (specs `prosta32.md`, `prosta28.md`, `lucka.md`): Prosta 32's white diamond lattice over blue glass with MARZYPOL, Prosta 28's X-braced base, stone stack and tree terraces with PROSTO, Łucka City's white stepped block, dark top and INTERBRUK board; left: Prosta 28's real height (OSM 80 m, photos ~92 m) |
| 156 | 19. Dzielnica (the Kolejowa estate) | Kolejowa / Przyokopowa | housing estate | ◐ | built 2026-11-07 from F's photos (spec `dzielnica19.md`): the mapped parts in cream with rust window frames, two blocks in the dark grid, garden podiums; photo pass D19-1 |
| 157 | Towarowa Towers | Kolejowa / Prosta | twin residential towers | ◐ | built 2026-11-07 from F's five photos: blue glass, staggered orange and gold frames, white spine, open crown with ASBUDKA (parody); the white blocks with orange balconies |
| 158 | NOHO ONE building site (the old Polfa drug works) | Kasprzaka / Karolkowa | building site | ◐ | built 2026-11-07 as a site under construction (OHO ONE, parody): four concrete frames, cores, three cranes, the yard; finished cascades later, from photos |
| 159 | Stacja Muzeum (old Warszawa Główna) | Towarowa 3 | railway museum | ◐ | built 2026-11-07 from the Mac's Commons photos (spec `stacja_muzeum.md`): the barrel hall's arched cream front with WARSZAWA GŁÓWNA, the Towarowa wing, 17 engines and coaches on the four sidings, water crane, lamps, white fence |
| 160 | Nocny Targ (Nocny Market) | Towarowa 3, the old platforms | night market | ◐ | built 2026-11-07 from F's photos: two rusty platform canopies (single pitch over kiosks; twin gables over stalls), coloured tubes, bulb strings, painted benches, a food truck; parody NOCNY TARG |

Tier C (named tenements, offices, embassies, small institutions) has no rows here: Part 2
lists all of them street by street with their status.

## Part 3. The top not-done items, one thread each

Proposed order for the next threads (photos first, see "Why some places were rebuilt"):

1. ~~Most Poniatowskiego (14)~~: built from photos 2026-11-02.
2. ~~Muzeum Powstania Warszawskiego (21): the brick power station, the wall, the tower.~~ Done 2026-11-02 (spec `mpw.md`).
3. Pomnik Powstania Warszawskiego and Plac Krasińskich's palace (22, 79).
4. Hotel Warszawa / Prudential (29) and Cedet (30): the start area's south.
5. Rondo ONZ towers by photo: Q22 and Rondo 1 first (28).
6. The monuments pass: Nike, Słowacki, Starzyński, Mały Powstaniec, Kiliński, Plac Piłsudskiego's (65-68), then 69, 70, 113-116. Started 2026-11-02: every OSM monument and plaque now stands as a generic piece (tools/bake_monuments.py); Plac Piłsudskiego's (68) built from photos 2026-11-02, and 65-67, 69, 70 the same day from the Mac's photo reports (part 2). Left: 113-116.
7. Plac Bankowy's colonnades (64): DONE 2026-11-02 (photo build), with Filharmonia (77) and Teatr Polski (83).
8. Świętokrzyska's big three: NBP, Poczta Główna, PAST-a (75, 76, 78).
9. Photo re-pass of the outline builds on the first ten minutes' routes: Varso, Złote Tarasy, Teatr Wielki, Krakowskie Przedmieście (7, 8, 18, 24-27). Krakowskie Przedmieście's gather list is parked in QUESTIONS (2026-11-02).
10. Praga's faces: the cathedral of St Michael and St Florian, Koneser, Bazar Różyckiego, Wschodnia (84-86, 73). The cathedral and the bazaar built from the Mac's photo reports 2026-11-02; Koneser and the fountain park (88) lie in the box's cut north-east corner, off the map.

11. **Warsaw modernism and brutalism (F, 2026-11-03, high priority)**: Młotek, Kozia 9, Karowa 18a first
    (147-149), then Żyletkowiec, Dom Chłopa, NBP, Kopernika, Za Żelazną Bramą, Torwar, the ministry,
    Dom Słowa Polskiego and the re-passes (docs/design/modernism-collection.md M1-M17; BGK, M10, built
    2026-11-03), and the "Betonowy album" quest once the first three land.

Tier C street passes (Part 2's named outlines and points, street by street, no photo builds): Nowogrodzka's
bar strip, pass 1 (2026-11-03: eight parody bar fascias, pavement crowds at night); Mazowiecka's clubs, pass 1 (2026-11-03: five parody club fascias, queues after midnight); Wilcza and Poznańska's bars, pass 1 (2026-11-03: seven parody bar fascias, pavement crowds at night); Praga's old streets, pass 1 (2026-11-03: six parody bar fascias on Okrzei, Wrzesińska, Kijowska and Targowa; Ząbkowska itself is off the map).

<!-- streets:start -->
## Part 2. Street by street

Generated by `python3 -I tools/city_inventory.py` from the map data and Part 1. Ranked places in bold with their number; the rest are named outlines in OpenStreetMap (tier C), marked "◐ model" when a hand-built site stands in them (the church kit, the hotels' fronts), "○ in game" when the game names them (a card, a sign, a skin), "○ old-town dress" for the dressed Old Town houses, and ✗ when they are a plain block. Streets are the nearest address point, so a corner building can sit on the cross street. After the buildings, each street lists the OpenStreetMap points the map does not bake as buildings (monuments, murals, bars, museums, stages, malls, hotels, offices; real venue names, which the game only shows as parodies) and a count of its plaques and memorial stones. Monuments marked "○ in game" stand as a generic piece at least (tools/bake_monuments.py, game/data/monuments.json), as do the plaques.

### Across the city (5 places)

- **many streets**: **#74 Metro stations: Centrum, Świętokrzyska, Ratusz-Arsenał, Politechnika, Rondo ONZ, Rondo Daszyńskiego, Nowy Świat-Uniwersytet, Centrum Nauki Kopernik, Stadion Narodowy, Dworzec Gdański** ○; **#141 Talking benches (ławeczki): Ławeczka Jana Karskiego, Ławeczka Jana Nowaka-Jeziorańskiego, Ławeczka księdza Twardowskiego, Ławeczka Henryka Sławika i Józsefa Antalla, Ławeczka Studenta, Ławeczka Jerzego Janickiego, Ławeczka Wandy Tazbir** ○; **#142 Monuments OSM adds: Janusz Korczak, Witold Pilecki, Napoleon Bonaparte, Monte Cassino, Pomnik Ofiar Rzezi Woli, Kobietom Powstania Warszawskiego, Jan Rodowicz "Anoda", Wojciech Korfanty, Ignacy Jan Paderewski, Wojciech Bogusławski, Stanisław Moniuszko, Kotwica z żaglowca szkolnego "Lwów"** ○; **#143 Murals (26 named in OSM)** ✗; **#144 Plaques and memorial stones (about 690: Tchorek's Uprising plaques, stones, steles)** ○

### Praga (50 places)

- **Targowa**: **#86 Bazar Różyckiego** ★; **#135 Galeria Wileńska and Dworzec Wileński** ✗; Pasaż Handlowy "Targowa 33A" (commercial) ✗; *monuments:* Praski miś ○ in game, Zaklęty Rewir ✗; *murals:* Foton ✗, Molozol - Muchozol - Sanitozol ✗; *bars:* Pub & Bar Kijowska 2 ✗; *museums:* Muzeum Warszawskiej Pragi ✗, Osińska, Litawińska, Szczodry ✗, Wind0wlicker ✗, Środek ✗; *plaques and memorial stones:* 2
- **Lubelska**: **#73 Warszawa Wschodnia** ◐; Klasztor pallotynów (monastery) ✗; Koleje Mazowieckie (offices) ✗; Warszawa Wschodnia (podmiejski) (station) ✗; *murals:* Jan Karski ○ in game
- **Floriańska**: **#84 Bazylika Katedralna Świętego Michała Archanioła i Świętego Floriana Męczennika** ★; *monuments:* Ks. Ignacy Jan Skorupka ○ in game, Pomnik Praskiej Kapeli Podwórkowej ○ in game; *plaques and memorial stones:* 4
- **Księdza Ignacego Kłopotowskiego**: Centrum Praha (public) ✗; Hit ✗; Kamienica Juliana Różyckiego (flats) ✗; Rainbow Center (government) ✗; Stacja Dializ (hospital) ✗; Symfonia (flats) ✗; *monuments:* Warszawski Południk Zerowy ✗, Witold Pilecki ○, Сккльптура ангела ○ in game; *hotels:* Hetman ✗; *plaques and memorial stones:* 3
- **Stefana Okrzei**: Kamienica pod Sowami (flats) ✗; Latarnia (flats) ✗; Manufaktura Praska (flats) ✗; Na Okrzei (flats) ✗; Port II (flats) ✗; Rezydencja Symfonia (flats) ✗; *monuments:* Pomnik Kościuszkowców ○ in game; *murals:* Generational connection ✗, Miejska dżungla ✗; *bars:* Bazar ★, Centrum Zarządzania Światem ✗, Inclusive Barista ✗; *stages:* Mazowiecki Teatr Muzyczny im. Jana Kiepury ✗; *plaques and memorial stones:* 1
- **Grochowska**: Kościół pw. Matki Boskiej Zwycięskiej (cathedral) ◐ model; Allegro ✗; Plebania (presbytery) ✗; SPC (shop) ✗; *monuments:* Kąpiąca się ○ in game, Pomnik Poległych i zmarłych ○ in game; *murals:* E. Wedel 1851 ✗; *plaques and memorial stones:* 4
- **Jana Zamoyskiego**: Dworzec PKP Warszawa Stadion (station) ○ in game; Hotel Dedek Park (hotel) ✗; *monuments:* 70 lat Totalizatora Sportowego ○ in game, Tancerka ○ in game; *bars:* Bar pod Kufelkiem ✗, Sala bankietowa Dedek Park ✗; *museums:* Muzeum Fabryka Czekolady Wedla ✗; *hotels:* Tulip Residences Warsaw Targowa ✗; *plaques and memorial stones:* 1
- **Sokola**: Marcowy Zając (offices) ✗; Narodowe Centrum Sportu (offices) ✗; *plaques and memorial stones:* 1
- **Bliska**: Bliska Residence ✗; *murals:* Bird and snake murales ✗
- **Francuska**: Restauracja Dom Polski (house) ✗; *plaques and memorial stones:* 4
- **Genewska**: Boathouse ✗; Wisełka (hotel) ✗
- **Jagiellońska**: Prokuratura Rejonowa Warszawa-Praga Północ (offices) ✗; *stages:* Baj ✗
- **Jakuba Jasińskiego**: Budynek A (hospital) ✗; Przychodnia przyszpitalna (hospital) ✗
- **Jakubowska**: Dom Funkcjonalny (semidetached_house) ✗; *monuments:* Kazimierz Górski ○ in game, Sztafeta ○ in game, pomnik Bohaterów 10 Pułku Piechoty 4 Dywizji im. Kilińskiego ○ in game; *bars:* Strefa Kibica ✗
- **Józefa Sierakowskiego**: Centralne Biuro Śledcze Policji (public) ✗; *bars:* BRAĆ polskie wina ✗; *plaques and memorial stones:* 1
- **Katowicka**: Dajemy Dzieciom Siłę (offices) ✗; *museums:* Galeria Le Guern ✗; *plaques and memorial stones:* 1
- **Markowska**: Zbór „Praga dla Chrystusa” ✗; *murals:* Mural Jamnik ✗
- **Olszowa**: Urząd Stanu Cywilnego Warszawa Praga-Północ (government) ✗; *plaques and memorial stones:* 1
- **Panieńska**: Szpitalny Oddział Ratunkowy (hospital) ✗; *monuments:* Kajaki jesienią ○ in game
- **Skaryszewska**: Kaplica pw. Matki Boskiej Częstochowskiej (church) ✗; *plaques and memorial stones:* 5
- **Wał Miedzeszyński**: Ambasada Gruzji ✗; *bars:* Erewań ✗
- **Wrzesińska**: DOSIR "Prawy Brzeg" (sports) ✗; *murals:* Praski Grajek ✗; *bars:* Port Winoland ✗
- **Aleja Jerzego Waszyngtona**: *monuments:* Edward Mandell House ○ in game, Ignacy Jan Paderewski ○, Jerzy Waszyngton ○ in game; *plaques and memorial stones:* 2
- **Brzeska**: *plaques and memorial stones:* 6
- **Dąbrowiecka**: *monuments:* René Goscinny ○ in game; *bars:* Hocki Klocki w Lunaparku ✗; *plaques and memorial stones:* 1
- **Elsterska**: *plaques and memorial stones:* 2
- **Finlandzka**: Pracownia Sztuk Plastycznych (offices) ✗
- **Kijowska**: Ośrodek Dokumentacji Geodezyjnej PKP (offices) ✗
- **Kryniczna**: Białoruski Dom w Warszawie (commercial) ✗
- **Królowej Aldony**: Ambasada Łotwy (offices) ✗
- **Lipska**: *plaques and memorial stones:* 2
- **Luksemburska**: Dwór Genzlów (house) ✗
- **Obrońców**: *monuments:* Agnieszka Osiecka ○ in game; *bars:* Wine Bar ✗; *plaques and memorial stones:* 1
- **Poselska**: Rezydencja ambasadora Portugalii (offices) ✗
- **Radziłowska**: *plaques and memorial stones:* 1
- **Walecznych**: *plaques and memorial stones:* 2
- **Zakopiańska**: *plaques and memorial stones:* 2
- **Zwycięzców**: *monuments:* Bolesław Prus ◐; *plaques and memorial stones:* 2
- **Łotewska**: *plaques and memorial stones:* 1

### Stare Miasto (53 places)

- **Rynek Starego Miasta**: **#12 Rynek Starego Miasta and its Syrenka** ◐; **#39 Old Town and New Town tenements: Kamienica Pod Bazyliszkiem, Pod Murzynkiem, Fukierowska, Baryczkowska, Pod Okrętem** ○; Kamienica Balcerowska (flats) ○ old-town dress; Kamienica Baryczkowska (flats) ○ old-town dress; Kamienica Busserowska (flats) ○ old-town dress; Kamienica Falkiewiczowska (flats) ○ old-town dress; Kamienica Kazubowska (flats) ○ old-town dress; Kamienica Kleinpoldowska (flats) ○ old-town dress; Kamienica Klemensowska (flats) ○ old-town dress; Kamienica Pod Murzynkiem ○ old-town dress; Kamienica Talentich (flats) ○ old-town dress; Staromiejski Dom Kultury Słowa ✗; *monuments:* Syrenka Warszawska ◐; *museums:* Muzeum Literatury ✗, Muzeum Warszawy ✗, Muzeum Świat Iluzji ✗; *plaques and memorial stones:* 8
- **Miodowa**: **#99 Pałac Paca, Pałac Branickich (Miodowa), Pałac Prymasowski, Pałac Blanka, Pałac Jabłonowskich** ✗; **#100 Katedra polowa, the Cerkiew, Kapucyni (Miodowa churches)** ◐; Cerkiew pw. Zaśnięcia Najświętszej Marii Panny (church) ◐ model; Katedra polowa Wojska Polskiego Najświętszej Maryi Panny Królowej Polski (church) ◐ model; Bursa Szkolnictwa Artystycznego (dormitory) ✗; Monaster Zaśnięcia Najświętszej Bogurodzicy i św. Jozafata biskupa i męczennika (monastery) ✗; *stages:* Teatr Collegium Nobilium ✗; *plaques and memorial stones:* 4
- **Nowomiejska**: **#23 Barbakan and the city walls** ◐; Kamienica Czechowska (flats) ○ old-town dress; Kamienica Montelupich (flats) ○ old-town dress; Kamienica Smockich (flats) ○ old-town dress; Kamienica pod św. Anną (flats) ○ old-town dress; *bars:* Same Krafty Vis-a-Vis ✗; *plaques and memorial stones:* 3
- **Podwale**: **#67 Pomnik Małego Powstańca and Pomnik Jana Kilińskiego** ★; Kościół pw. Świętego Ducha (church) ◐ model; Archiwum Główne Akt Dawnych (public) ✗; *museums:* Muzeum Domków Lalek, Gier i Zabawek ✗; *plaques and memorial stones:* 4
- **Jezuicka**: Archikatedra pw. Świętego Jana Chrzciciela ○ in game; Kamienica Długoszowa ○ old-town dress; Kamienica Pod Okrętem (flats) ○ old-town dress; Sanktuarium Matki Bożej Łaskawej ✗; *museums:* Muzeum Zimnej Wojny ✗; *plaques and memorial stones:* 6
- **Kanonia**: Arkady Kubickiego ○ in game; Dwór Dziekana Kapituły (flats) ✗; Stołeczne Centrum Edukacji Kulturalnej ✗; *monuments:* Dzwon na Kanonii ✗, Siłacz ○ in game; *museums:* Galeria Obok ZPAF ✗, Muzeum Archidiecezji Warszawskiej ✗, Stara Galeria ✗; *stages:* Teatr Małego Widza ✗; *plaques and memorial stones:* 9
- **Piwna**: Kamienica Loupich (flats) ○ old-town dress; Kościół pw. Świętego Marcina (church) ◐ model; Dom Zakonny Sióstr Franciszkanek Służebnic Krzyża (monastery) ✗; *plaques and memorial stones:* 5
- **Plac Zamkowy**: Kamienica Pod Pelikanem ○ old-town dress; Biblioteka Publiczna m. st. Warszawy (flats) ✗; Mansjonaria (flats) ✗; *monuments:* Jan Zachwatowicz ○ in game; *museums:* Zamek Królewski w Warszawie ✗; *hotels:* Castle Inn ✗; *plaques and memorial stones:* 12
- **Szeroki Dunaj**: Kamienica Fukierowska (flats) ○ old-town dress; Kamienica Gizińska (flats) ○ old-town dress; Dom Szewców ✗; *monuments:* Rycerz ○ in game; *museums:* Muzeum Cechu Rzemiosł Skórzanych ✗; *plaques and memorial stones:* 2
- **Długa**: Kamienica Gaszyńskiego ○ old-town dress; Komora Celna ✗; *monuments:* Pomnik Powstania Warszawskiego ★; *museums:* Powstanie Warszawskie - Spragnieni Wolności ✗; *plaques and memorial stones:* 10
- **Freta**: Kamienica Piotra Hawermana ○ old-town dress; Kamienica Schenka ○ old-town dress; *bars:* Elephant ✗, Piwnica Pod Michałem ✗; *museums:* Muzeum Marii Skłodowskiej-Curie ✗; *plaques and memorial stones:* 3
- **Krzywe Koło**: Kamienica Gębińska (flats) ○ old-town dress; Kamienica Mirosławska (flats) ○ old-town dress; *bars:* Same Krafty ✗; *museums:* Instytut Słowacki ✗; *stages:* Scena Letnia w Lapidarium ✗
- **Brzozowa**: Kamienica Bornbachów (flats) ○ old-town dress; *monuments:* Piosenka dla Warszawy ○ in game; *museums:* Muzeum Odbudowy Starówki ✗; *plaques and memorial stones:* 3
- **Bugaj**: Wieczór nad Wisłą (boat) ○ in game; *monuments:* Julian Kulski i Stefan Starzyński ○ in game; *museums:* Plenerowa Galeria Zbigniewa Maleszewskiego ✗
- **Mostowa**: Warszawskie Centrum Innowacji Edukacyjno-Społecznych i Szkoleń ✗; *monuments:* Galeria Rzeźby ○ in game; *plaques and memorial stones:* 4
- **Piekarska**: Dom Prowincjalny Sióstr Elżbietanek (convent) ✗; *monuments:* Jan Kiliński ★; *museums:* Muzeum Rzemiosł Artystycznych i Precyzyjnych ✗; *plaques and memorial stones:* 5
- **Świętojerska**: Mazowieckie Samorządowe Centrum Doskonalenia Nauczycieli (offices) ✗; *museums:* Centrum Design ✗, Muzeum Grawitacji ✗
- **Jana Kilińskiego**: *plaques and memorial stones:* 1
- **Nowy Zjazd**: *plaques and memorial stones:* 2
- **Rycerska**: *monuments:* Oświęcim II ○ in game; *museums:* Muzeum Farmacji ✗
- **Wąski Dunaj**: *monuments:* Mały Powstaniec ★; *bars:* Podwale Bar and Books ✗

### Muranów (47 places)

- **Mordechaja Anielewicza**: **#20 Muzeum Historii Żydów Polskich Polin and Pomnik Bohaterów Getta** ★; SM Miła (offices) ✗; *monuments:* Pierwszy Pomnik Bohaterów Getta ○ in game, Ławeczka Jana Karskiego ○; *bars:* Paradox Cafe ✗; *plaques and memorial stones:* 1
- **Stawki**: **#70 Umschlagplatz memorial** ★; Budynek dydaktyczny - Szkoła Rodzenia "Baby Care" (hospital) ✗; *plaques and memorial stones:* 4
- **Inflancka**: **#132 Gdański Business Center** ◐
- **Dzielna**: Hala Sportowa SP210 (school) ✗; Kamienica Muranów (flats) ✗; Przedszkole nr 124 (kindergarten) ✗; Społem (shop) ✗; Spółdzielnia Mieszkaniowa "Muranów" (offices) ✗; Szkoła Podstawowa nr 210 im. Bohaterów Pawiaka (school) ✗; *monuments:* Drzewo Pawiackie ○ in game; *museums:* Galeria LETO ✗, Muzeum Więzienia Pawiak ✗; *plaques and memorial stones:* 6
- **Długa**: Biuro Rzecznika Praw Obywatelskich (public) ✗; Pałac Marii z Lubomirskich Radziwiłłowej (palace) ✗; Pałac Teppera-Dückerta (palace) ✗; Pałac na Podkańskiem ✗; Wydział Nauk Ekonomicznych UW ✗; Złota Milonga ✗; *monuments:* Kobietom Powstania Warszawskiego ○; *hotels:* Metalowcy ✗; *plaques and memorial stones:* 5
- **Aleja „Solidarności”**: Kościół Ewangelicko-Reformowany (church) ◐ model; Dom Dysydentów ✗; Kamienica Jacobsona (flats) ✗; *monuments:* Ignacy Paderewski ○ in game; *murals:* Ludziom Alei Solidarności/Ulicy Leszno ✗, Mural Emiliana Kamińskiego ✗, Ulica Leszno ✗; *bars:* Paragraf ✗; *stages:* Teatr Kamienica ✗; *plaques and memorial stones:* 6
- **Nowolipki**: Kościół pw. Świętego Augustyna (church) ◐ model; Pałac Mostowskich (public) ✗; ZGN Wola (offices) ✗; *monuments:* Miejsce ukrycia Archiwum Ringelbluma ○ in game, Pomnik Żołnierzy 1 Armii WP ○ in game; *murals:* Bohdan Lahert ✗, Cytaty w Esperanto ✗, Warszawscy Muzykanci ✗; *bars:* Right Place ✗, Spawn ✗, The Backstage Bar ✗; *museums:* Ewa Opałka ✗, Państwowe Ognisko Artystyczne "Nowolipki" ✗; *stages:* Potem o Tem ✗; *plaques and memorial stones:* 4
- **Senatorska**: Dom Bankowy Landaua ○ in game; Pałac Błękitny ○ in game; Pałac Mniszchów ○ in game; *monuments:* Święty Jan Nepomucen ○ in game; *stages:* Teatr Żydowski ✗; *plaques and memorial stones:* 4
- **Spokojna**: Izba Wytrzeźwień ✗; Katakumby ✗; Kościół pw. Świętego Karola Boromeusza ✗; *bars:* Mielżyński ✗
- **Karmelicka**: Kościół parafialny pw. Narodzenia Najświętszej Maryi Panny (church) ◐ model; Akademia WSB Wydział Zamiejscowy w Warszawie (university) ✗; *monuments:* Umschlagplatz ★; *plaques and memorial stones:* 2
- **Niska**: Bursa nr 6 w Warszawie (dormitory) ✗; Rezydencja Niska 30 (flats) ✗; *monuments:* Pomnik litery A ○ in game; *plaques and memorial stones:* 1
- **Nowolipie**: Centrum Aktywności Międzypokoleniowej „Nowolipie” (public) ✗; Pałac Działyńskich (university) ✗; *murals:* Kobiety Muranowa ✗; *museums:* Galeria Szydłowski ✗; *plaques and memorial stones:* 2
- **Zygmunta Słomińskiego**: Apartamenty Gdański ✗; Słomińskiego Art Office (offices) ✗; *stages:* Cinema City ✗; *plaques and memorial stones:* 3
- **Świętojerska**: Sąd Najwyższy ○ in game; Instytut Pamięci Narodowej ✗; *monuments:* Rybacy ✗; *museums:* Pałac Rzeczypospolitej ✗; *plaques and memorial stones:* 3
- **Aleja Jana Pawła II**: Kamienica Trachtenberga ✗; *murals:* Kapitan Zbigniew Ścibor-Rylski "Motyl" ✗; *plaques and memorial stones:* 3
- **Antonia Corazziego**: Carrefour Express (shop) ✗; *museums:* Żydowski Instytut Historyczny ✗; *plaques and memorial stones:* 1
- **Generała Władysława Andersa**: Ibis Warszawa Stare Miasto ✗; *monuments:* Poległym i Pomordowanym na Wschodzie ★; *bars:* Craft Beer Muranów ✗; *stages:* Muranów ○; *plaques and memorial stones:* 4
- **Ludwika Zamenhofa**: Dom studencki nr 4 (dormitory) ✗; *monuments:* Drzewo Wspólnej Pamięci ✗, Emanuel Ringelblum ○ in game, Józef Lewartowski ○ in game, Michal Klepfisz ○ in game, Pomnik Bohaterów Getta ★, Powstanie w Getcie ○ in game; *museums:* Autonomia ✗, Jednostka ✗, Program ✗; *plaques and memorial stones:* 2
- **Miła**: NZOZ Karmelicka (commercial) ✗; *monuments:* Arie Wilner ○ in game, Mordechaj Anielewicz ○ in game; *plaques and memorial stones:* 3
- **Okopowa**: Vizja Park (offices) ✗; *plaques and memorial stones:* 1
- **Stare Nalewki**: Villa Bogoria (flats) ✗; *monuments:* Monte Cassino ○, Pomnik Ofiar w Pasażu Simonsa ○ in game; *museums:* Państwowe Muzeum Archeologiczne ✗; *plaques and memorial stones:* 4
- **Dzika**: *monuments:* Getto Żydowskie ○ in game; *plaques and memorial stones:* 1
- **Józefa Lewartowskiego**: *plaques and memorial stones:* 1
- **Nalewki**: *plaques and memorial stones:* 1
- **Nowiniarska**: *plaques and memorial stones:* 2
- **Orla**: *plaques and memorial stones:* 1
- **Pawia**: Pływalnia Foka (sports hall) ✗
- **Plac Bankowy**: *monuments:* Eugeniusz Kwiatkowski ○ in game, Juliusz Słowacki ★, Stefan Starzyński ★; *museums:* Galeria Porczyńskich ✗; *plaques and memorial stones:* 7
- **Stanisława Dubois**: *monuments:* Frumka Płotnicka ○ in game, Icchak Nyssenbaum ○ in game, Meir Majerowicz ○ in game, Paweł Frenkel i Dawid Apfelbaum ○ in game; *plaques and memorial stones:* 2

### Śródmieście (97 places)

- **Świętokrzyska**: **#75 Narodowy Bank Polski** ✗; **#76 Poczta Główna** ★; **#105 Ministerstwo Finansów** ◐; Instytut Ekonomiki Rolnictwa i Gospodarki Żywnościowej ✗; *monuments:* Pomnik Powstańców Warszawy ○ in game, Ławeczka Laury Petrarki ○ in game; *bars:* Bar Studio ◐ (garden and sign, 2026-11-07), Chillin ✗, Królik ✗; *museums:* Centrum Pieniądza NBP ✗; *stages:* Teatr Lalka ◐ (sign), Teatr Studio ◐ (sign); *plaques and memorial stones:* 1
- **Bracka**: **#80 Vitkac** ★; **#81 Dom Towarowy Braci Jabłkowskich** ★; Kamienica Zofii Kiersnowskiej (flats) ✗; Pałac Brzozowskich (flats) ✗; *monuments:* Pisklę. Drozd śpiewak ○ in game; *bars:* Mały Wojtek ✗; *museums:* Instytut Goethego ✗
- **Chmielna**: **#7 Varso Tower (with Varso I, Varso II)** ◐; **#97 Kawiarnia and bar street of Chmielna, Mokotowska, Hoża, Poznańska** ○; Kamienica Braci Jabłkowskich (commercial) ✗; Kamienica Lilpopów (flats) ✗; *bars:* Bless ✗, Connect ✗, Frodo ✗, HighGarden Rooftop Lounge ✗, Hoppiness ✗; *stages:* Multikino ✗; *hotels:* Mamaison Residence Diana ✗, NYX ✗; *plaques and memorial stones:* 3
- **Jasna**: **#77 Filharmonia Narodowa** ★; **#103 Dom pod Orłami and Skwer Linearny na Złotej** ★; Centrum Jasna ✗; Kamienica Maksymiliana Harczyka (flats) ✗; *bars:* Jasna 1 ○ in game, Warszawska ★; *museums:* Muzeum Historii Spółdzielczości w Polsce ✗, Spotkania z Europą ✗; *plaques and memorial stones:* 1
- **Złota**: **#5 Złota 44** ★; **#8 Złote Tarasy (with Lumen, Skylight)** ◐; Kiseki (shop) ✗; Wojskowe Biuro Emerytalne ✗; *monuments:* Tindaro ○ in game; *murals:* Bez tytułu (Jacek Kuroń) 2020 ✗; *bars:* Hybrydy ✗, Kulturalna ✗; *museums:* Mi Polin Mezuzah Center ✗, Muzeum Ewolucji ✗, Muzeum Neonów ✗; *stages:* Kinoteka ◐ (sign at its door, 2026-11-07), Palladium ✗, Sala Kongresowa ◐ (sign); *malls:* TK Maxx ✗; *plaques and memorial stones:* 8
- **Królewska**: **#104 Hotel Wiktoria (Sofitel Victoria) and Królewska** ◐; **#106 Saski Crescent, Saski Park, Senator** ✗; *monuments:* Lech Kaczyński ○ in game, Pomnik Ofiar Tragedii Smoleńskiej ○ in game; *plaques and memorial stones:* 4
- **Zielna**: **#78 PAST-a** ★; Mała PAST-a (commercial) ✗; Pałac Janaszów (offices) ✗; *bars:* Inspector Lounge ✗, Piętro Niżej ✗; *plaques and memorial stones:* 4
- **Plac Grzybowski**: **#102 Plac Grzybowski and Kościół Wszystkich Świętych** ◐; Kamienica Brenkina ✗; *plaques and memorial stones:* 1
- **Bagno**: **#128 Atelier Residence, Rezydencja Foksal, Apartamenty Flare, Solec Residence, Złota Chmielna** ✗; *plaques and memorial stones:* 1
- **Próżna**: **#101 Synagoga Nożyków and Próżna's pre-war tenements (Kamienica Zalmana Nożyka, Kamienica Wolanowskiego)** ◐; *museums:* Austriackie Forum Kultury ✗
- **Szpitalna**: **#118 Kamienica Wedla** ✗; *bars:* Afera ✗, El Koktel ✗; *plaques and memorial stones:* 2
- **Marszałkowska**: Central Point ✗; Centrum Królewska ✗; Centrum Marszałkowska ✗; PKO BP ✗; Wolf Marszałkowska ✗; *monuments:* Pamięci Polaków poległych w II wojnie światowej ○ in game; *bars:* Capitol ✗; *museums:* Centralny Przystanek Historia ✗; *stages:* Teatr Capitol ✗, Teatr Kwadrat ✗; *plaques and memorial stones:* 2
- **Miodowa**: Kościół Przemienienia Pańskiego (church) ◐ model; Klasztor Ojców Kapucynów (monastery) ✗; Pałac Arcybiskupi d. Pałac Borchów (palace) ✗; Pałac Chodkiewiczów ✗; Pałac Szaniawskich (palace) ✗; *monuments:* Stefan Kardynał Wyszyński ◐, Ławeczka z "Bezdomnym Jezusem" ✗; *plaques and memorial stones:* 3
- **Senatorska**: Kościół Świętego Antoniego Padewskiego (church) ◐ model; Biuro Rent Zagranicznych Zakładu Ubezpieczeń Społecznych (offices) ✗; Kamienica Małachowskiego (offices) ✗; Pałac Biskupów Krakowskich (palace) ✗; Zakład Ubezpieczeń Społecznych ✗; *monuments:* #NieZapominajmy ○ in game, Maria Konopnicka ○ in game, Warszawska Nike ★; *bars:* Resort ✗, Verte Bar ✗; *stages:* Resort Komedii ✗; *hotels:* Bellotto ✗, Verte ✗; *plaques and memorial stones:* 8
- **Grzybowska**: Grzybowska Park (commercial) ✗; Osiedle "Graniczna" (flats) ✗; Pasaż Saski (flats) ✗; Radisson Collection Hotel (hotel) ✗; *monuments:* Piotr Drzewiecki ○ in game; *bars:* City Wine ✗, Cześć ✗, Executive Club Lounge ✗, Warshishawa ✗; *museums:* Station of Art ✗; *plaques and memorial stones:* 1
- **Nowogrodzka**: Hotel Metropol ○ in game; Novotel Warszawa Centrum ○ in game; Gmach Urzędu Telekomunikacyjnego i Telegraficznego (offices) ✗; N21 (offices) ✗; *bars:* Angel's ✗, Azyl ✗, Barbara ✗, Bardzo Bardzo ✗, Disparo ✗, Feliks Bar ✗, Ginnery ✗, Jabeerwocky ✗, Kufle i Kapsle ✗, Pinta ✗, Princesa ✗, Scity ✗, Steam Bar ✗, Weles ✗; *museums:* Instytut Cervantesa ✗; *hotels:* No.4 Residence ✗; *plaques and memorial stones:* 6
- **Aleje Jerozolimskie**: PKP Warszawa Śródmieście (station) ○ in game; Kamienica Hoserów (flats) ✗; Kamienica Lipińskiego (flats) ✗; *bars:* Bollywood Lounge ✗, Foxy ✗, Hood ✗, Lobby Bar ✗, Zebra Shot Bar ✗; *museums:* Fotoplastikon Warszawski ✗, Muzeum Narodowe w Warszawie ✗, Narodowe Muzeum Techniki ◐ (sign on the Palace, 2026-11-07); *stages:* Teatr Dramatyczny ◐ (sign and evening crowd, 2026-11-07); *plaques and memorial stones:* 9
- **Tadeusza Czackiego**: Brain Embassy (offices) ✗; Dom Technika (offices) ✗; Kapsuła Hostel (commercial) ✗; *plaques and memorial stones:* 3
- **Emilii Plater**: Warszawskie Centrum Finansowe ○ in game; Igrek ✗; *monuments:* Torreador ○ in game; *murals:* Rewolucja ✗; *bars:* Panorama Sky Bar ✗, Tosca ✗; *hotels:* Presidential ✗; *plaques and memorial stones:* 1
- **Kredytowa**: Ministerstwo Cyfryzacji (government) ✗; Urząd m.st. Warszawy (flats) ✗; *plaques and memorial stones:* 4
- **Mazowiecka**: Hotel Mazowiecki ✗; Okręg Warszawski Związku Polskich Artystów Plastyków ✗; *bars:* Bank Club ✗, Blu Club ✗, Czupito ✗, Enklawa ✗, La Pose ✗, Mazo ✗, Ritual ✗, Room 13 ✗, Sketch Nite ✗, Tygmont ✗; *museums:* Muzeum Etnograficzne ✗; *plaques and memorial stones:* 7
- **Twarda**: Spektrum Tower ○ in game; Biały Budynek (flats) ✗; *monuments:* Jan Paweł II ○ in game, You and Me ✗; *bars:* CodeRED ✗; *plaques and memorial stones:* 1
- **Widok**: Puro Warszawa Centrum (hotel) ○ in game; Widok Towers ○ in game; *bars:* Loreta Bar ✗, Ramona ✗, Sultan Club ✗; *museums:* Instytut Francuski ✗; *stages:* Atlantic ○; *plaques and memorial stones:* 1
- **Wierzbowa**: Kamienica Dmuszewskiego (offices) ✗; Kamienica Petyskusa ✗; *monuments:* Geodezja Europejska ○ in game, Wojciech Bogusławski ○; *museums:* Muzeum Teatralne ✗; *plaques and memorial stones:* 2
- **Aleja Jana Pawła II**: PZU Tower ○ in game; *plaques and memorial stones:* 2
- **Bielańska**: Kościół św. Brata Alberta i św. Andrzeja Apostoła (church) ◐ model; *plaques and memorial stones:* 8
- **Daniłowiczowska**: Reduta Bank Polski ○ in game; *plaques and memorial stones:* 1
- **Gabriela Piotra Boduena**: Naczelny Sąd Administracyjny (civic) ✗; *monuments:* Napoleon Bonaparte ○; *plaques and memorial stones:* 1
- **Henryka Sienkiewicza**: Urząd Ochrony Konkurencji i Konsumentów ✗; *bars:* Lemon Bar ✗, Oblako ✗, The Taps ✗
- **Krzysztofa Kamila Baczyńskiego**: Rezydencja Warecka (flats) ✗; *hotels:* Hotel Gromada Warszawa Centrum ✗
- **Mysia**: Polska Grupa Energetyczna ✗; *monuments:* Memoriał Wolnego Słowa ○ in game; *malls:* Muji ✗
- **Niecała**: PURO Warszawa Stare Miasto (hotel) ✗; *monuments:* Astronomia ○ in game, Chłopiec z łabędziem ✗, Inteligencja ○ in game, Prawda ○ in game, Sława ○ in game, Twórczość ○ in game, Wiedza ○ in game; *museums:* Muzeum Wódki ✗; *plaques and memorial stones:* 2
- **Nowy Świat**: Nowy Świat 2.0 ✗; *monuments:* Charles de Gaulle ◐, Palma ○ in game, Zamach na Café Club ✗; *bars:* Chicas & Gorillas ✗, La Casa del Habano ✗, Newonce Bar ✗, Rakieta ✗, Zagrywki ✗, Zamieszanie ✗, Świetlica Wolności ✗; *plaques and memorial stones:* 5
- **Plac Jana Henryka Dąbrowskiego**: Ambasada Włoch (flats) ✗; *monuments:* Chłopiec z krokodylem ○ in game; *plaques and memorial stones:* 1
- **Plac Stanisława Małachowskiego**: Kamienica Krasińskich ✗; *monuments:* Pomnik Peowiaka ○ in game; *plaques and memorial stones:* 1
- **Przeskok**: Astoria ✗; Wojewódzki Sąd Administracyjny (flats) ✗
- **Ptasia**: Tadeusz Kościuszko ○ in game; Pałac Lubomirskich ✗
- **Sienna**: Mercure Warszawa Centrum ✗; *museums:* Kolejkowo ✗; *plaques and memorial stones:* 2
- **Stanisława Moniuszki**: Telewizja Polska (commercial) ✗; *museums:* Instytut Liszta ✗; *plaques and memorial stones:* 4
- **Wojciecha Górskiego**: Restaura Górskiego (flats) ✗; *plaques and memorial stones:* 1
- **Żurawia**: Ministerstwo Aktywów Państwowych (government) ✗; *bars:* Beer & Bones ✗, Glam ✗, Hopito ✗, Izba ✗, Myata Lounge ✗, Wesele ✗; *stages:* Amondo ✗; *plaques and memorial stones:* 4
- **Aleja „Solidarności”**: Dom Pod Królami (palace) ✗
- **Aleksandra Fredry**: *monuments:* Architektura Wojskowa ○ in game, Arytmetyka ○ in game, Chwała ○ in game, Flora ○ in game, Geografia ○ in game, Historia ○ in game, Jesień ○ in game, Jowisz ○ in game, Malarstwo ○ in game, Medycyna ○ in game, Muzyka ○ in game, Rzeźbiarstwo ○ in game, Wenus ○ in game, Zima ○ in game; *bars:* Teatro Cubano ✗
- **Elektoralna**: Mazowiecki Instytut Kultury (public) ✗
- **Graniczna**: *monuments:* Syrenka ◐; *plaques and memorial stones:* 1
- **Jana Pankiewicza**: *plaques and memorial stones:* 1
- **Kapitulna**: Pałac Młodziejowskiego (palace) ✗
- **Krakowskie Przedmieście**: *plaques and memorial stones:* 1
- **Krucza**: Mercure Warszawa Grand ✗
- **Leona Schillera**: Sąd Rejonowy dla Warszawy-Mokotowa ✗
- **Mariańska**: Skysawa ○ in game
- **Moliera**: *monuments:* Polskim Artystom Baletu ○ in game, Stanisław Moniuszko ○; *bars:* Ave Pegaz ✗, Bar Rascal ✗; *stages:* Opera Narodowa ✗
- **Poznańska**: *bars:* Lobby bar ✗
- **Rondo ONZ**: *plaques and memorial stones:* 1
- **Smolna**: *monuments:* Generał Maria Wittek ✗
- **Warecka**: *plaques and memorial stones:* 2
- **Zgoda**: *monuments:* Neon "Warszawa" ✗; *bars:* Metropolis ✗, Niewinność ✗, Quiz Game ✗, Shamrock ✗; *plaques and memorial stones:* 4
- **Śliska**: *bars:* +One Bar ✗, Back2Rock ✗, Śliska The Lounge ✗; *museums:* Muzeum Getta Warszawskiego (w budowie) ✗; *plaques and memorial stones:* 1
- **Świętej Barbary**: Urząd Dzielnicy Śródmieście ✗

### Trakt Królewski (78 places)

- **Krakowskie Przedmieście**: **#25 Kościół św. Anny** ◐; **#26 Hotel Bristol and Hotel Europejski** ★; **#27 Pałac Prezydencki** ◐; **#32 Pomnik Mikołaja Kopernika and Pałac Staszica** ◐; **#33 Pomnik Adama Mickiewicza** ★; **#34 Kościół Świętego Krzyża** ◐; **#35 Brama Uniwersytetu Warszawskiego and Pałac Kazimierzowski** ★; **#36 Kościół Wizytek, Kościół Karmelitów** ◐; **#37 Pałac Potockich, Kordegarda, Pałac Czapskich** ★; **#108 Uniwersytet: Auditorium Maximum, Stary BUW, Biblioteka Królewska** ✗; **#117 Pomnik Kardynała Wyszyńskiego, Pomnik Bolesława Prusa** ◐; **#136 Skwer Hoovera's pavilions and the Christmas lights** ✗; **#138 Muzeum Karykatury, Kinomuzeum, Muzeum Niepodległości, Muzeum Wodociągów** ✗; Kościół Niepokalanego Poczęcia Najświętszej Maryi Panny (church) ◐ model; Kościół Wniebowzięcia Najświętszej Maryi Panny i świętego Józefa Oblubieńca (church) ○ in game; Kościół pw. Świętego Krzyża (church) ○ in game; Kościół pw. Świętej Anny (church) ○ in game; Centrum Nauczania Języków Obcych UW (university) ✗; Departament Mecenatu Państwa Ministerstwa Kultury i Dziedzictwa Narodowego ✗; Dom Polonii (offices) ✗; Dziekanka (offices) ✗; Instytut Filologii Klasycznej UW (university) ✗; Instytut Kultury Polskiej UW (university) ✗; Kamienica Heyna (flats) ✗; Kamienica Roesslera i Hurtiga (shop) ✗; Kamienica Skalskiego (flats) ✗; Narodowy Instytut Kultury i Dziedzictwa Wsi (public) ✗; Nowa Dziekanka (dormitory) ✗; Wydział Filozofii UW (university) ✗; Wydział Geografii i Studiów Regionalnych UW (university) ✗; Wydział Historii UW (university) ✗; Wydział Nauk Politycznych i Studiów Międzynarodowych (university) ✗; Wydział Prawa i Administracji UW (university) ✗; *monuments:* Adam Mickiewicz ◐, Józef Piłsudski ○ in game, Józef Poniatowski ◐, Matka Boska Passawska ○ in game, Mikołaj Kopernik ◐, Ławeczka Studenta ○; *bars:* Indeks ✗, Klar ✗, Longbar ✗, Molly Malone's ✗; *museums:* Galeria Instytutu Pileckiego w Domu Bez Kantów ✗; *stages:* Kino Kultura ✗; *hotels:* Jess ✗; *plaques and memorial stones:* 33
- **Nowy Świat**: **#40 Nowy Świat tenements and palaces (Zamoyski, Mikulski, Bürger, Jasiński, Kossakowski)** ○; **#48 Dom Partii and Rondo de Gaulle'a's palm** ◐; **#49 Pawilony za Nowym Światem** ◐; Kamienica Bürgera (flats) ○ in game; Kamienica Jasińskiego (flats) ○ in game; Kamienica Mikulskiego przy Nowym Świecie 53 (flats) ○ in game; Kamienica Mikulskiego przy Nowym Świecie 55 (flats) ○ in game; Pałac Kossakowskich (commercial) ○ in game; Pałac Zamoyskich (university) ○ in game; *monuments:* Jeleń ○ in game, Melchior Wańkowicz ○ in game, Pomnik Partyzanta Armii Ludowej ○ in game, Wojciech Górski ○ in game; *murals:* Mural Kory Jackowskiej ✗; *bars:* Babajaga ✗, Biały Nalew ✗, CafeFajka ✗, Cybermachina ✗, Cynamon ✗, Do Dna ✗, Dom Whisky ✗, Fajka Bar ✗, Ginger ✗, High Heels ✗, Hopster ✗, In Side ✗, Jolly Joker ✗, Klepsydra ✗, Klubowa No.24 ✗, Komix ✗, Labirynt ✗, Lenistwo ✗, Manhattan ✗, Mezza ✗, Och! & Ach! ✗, Pijalnia Wódki i Piwa ✗, Precedens ✗, Shot Gun ✗, Szprycer ✗, The Club No 1 ✗, Zakątek ✗, Żyrafa ✗; *hotels:* Colette ✗, Teatro ✗; *plaques and memorial stones:* 17
- **Plac Trzech Krzyży**: **#41 Kościół Świętego Aleksandra and Plac Trzech Krzyży** ◐; **#119 Kamienica pod Gryfami, Kamienica Johna** ✗; *bars:* Wozownia ✗; *plaques and memorial stones:* 2
- **Karowa**: **#149 Karowa 18a (1978, Dąbrowski, Kuźmienko, Nowak, Sembrat)** ★; Biuro Bezpieczeństwa Narodowego (government) ✗; Budynek "pod Wizytkami" (university) ✗; Dawne Centrum Informatyczne UW (university) ✗; Instytut Slawistyki Zachodniej i Południowej UW (university) ✗; Klasztor Sióstr Wizytek (convent) ✗; Polskie Towarzystwo Higieniczne ✗; Wydział Socjologii (offices) ✗; *monuments:* Ławeczka księdza Twardowskiego ○; *bars:* Karova ✗; *museums:* Dom Spotkań z Historią ✗; *plaques and memorial stones:* 5
- **Kozia**: **#148 Kozia 9 (1974-76, Kuźmienko and Sembrat)** ★; Pałac Wesslów ✗; *plaques and memorial stones:* 1
- **Oboźna**: Collegium Iuridicum III (university) ✗; Stołówka Uniwersytecka (university) ✗; Wydział Archeologii UW (university) ✗; Wydział Kultur Azji i Afryki (university) ✗; Wydział Neofilologii (university) ✗; Wydział Polonistyki UW (university) ✗; *monuments:* Kazimierz Dejmek ○ in game, Leon Schiller ○ in game; *bars:* Gi Gi ✗, Space Games Pub ✗; *hotels:* Flaner ✗; *plaques and memorial stones:* 8
- **Królewska**: Departament Wojskowej Służby Zdrowia (offices) ○ in game; Dom Bez Kantów ○ in game; Kamienica Grodzickiego ✗; Oficyna Pałacu Potockich (Archiwum UW) (university) ✗; Pałac Tyszkiewiczów-Potockich (university) ✗; *monuments:* Stefan Wyszyński ◐; *bars:* Laco ✗; *museums:* Muzeum Uniwersytetu Warszawskiego ✗; *hotels:* Tiffi ✗; *plaques and memorial stones:* 3
- **Bracka**: Polska Agencja Prasowa (offices) ✗; Wydział Stosowanych Nauk Społecznych i Resocjalizacji UW (university) ✗; *bars:* Margariteros ✗, Niebo ★; *plaques and memorial stones:* 3
- **Senatorska**: Kamienica Prażmowskich (flats) ✗; Pałac Małachowskiego (flats) ✗; *monuments:* Fragmenty Kolumny Zygmunta ○ in game, Kolumna Zygmunta ◐; *stages:* PolkLore & History. Folk & Heritage Show ✗; *hotels:* Dom Literatury ✗; *plaques and memorial stones:* 4
- **Aleje Jerozolimskie**: Kuratorium Oświaty (offices) ✗; *plaques and memorial stones:* 2
- **Bednarska**: Kamienica Wernera (flats) ✗; Państwowa Szkoła Muzyczna II St. nr 2 im. Fryderyka Chopina (school) ✗
- **Hoża**: Ministerstwo Nauki i Szkolnictwa Wyższego (government) ✗; *plaques and memorial stones:* 1
- **Romualda Traugutta**: Dom zakonny Księży Misjonarzy (monastery) ✗; *monuments:* Bartolomeo Colleoni ○ in game; *museums:* Salon Akademii ✗; *plaques and memorial stones:* 2
- **Sewerynów**: Dom Generalny Zgromadzenia Sługi Jezusa (flats) ✗; *plaques and memorial stones:* 1
- **Smolna**: Indigo (commercial) ✗; *bars:* Burley ✗, Smolna ★
- **Żurawia**: Ministerstwo Funduszy i Polityki Regionalnej (government) ✗; Ministerstwo Rozwoju i Technologii ✗
- **Aleje Ujazdowskie**: *monuments:* Wincenty Witos ○ in game; *plaques and memorial stones:* 2
- **Białoskórnicza**: *plaques and memorial stones:* 1
- **Chmielna**: *bars:* Queens ✗
- **Dobra**: *monuments:* Stanisław Jankowski "Agaton" ✗
- **Emiliana Konopczyńskiego**: *plaques and memorial stones:* 1
- **Foksal**: *bars:* Cafe Foksal ✗, Chaton ✗, Golden Moon ✗, Hany Bany ✗, Le Melange ✗, Meta na Foksal ✗, Ministerstwo Śledzia i Wódki ✗, Pawilon 31 ✗, Rozbiegówka ✗; *stages:* Teatr Sabat ✗; *plaques and memorial stones:* 3
- **Garbarska**: *plaques and memorial stones:* 1
- **Konstantego Ildefonsa Gałczyńskiego**: *museums:* Miejsce Projektów Zachęty ✗
- **Książęca**: *monuments:* Jakub Falkowski ○ in game, Ławeczka Wandy Tazbir ○; *plaques and memorial stones:* 6
- **Mariensztat**: *monuments:* Przekupka ○ in game; *hotels:* Mariensztat 8 Apartments ✗; *plaques and memorial stones:* 2
- **Mikołaja Kopernika**: *monuments:* Pomnik „Solidarności” ○ in game, Tadeusz Mazowiecki ○ in game; *plaques and memorial stones:* 4
- **Miodowa**: *bars:* Irish Pub ✗; *plaques and memorial stones:* 1
- **Okólnik**: *museums:* Objekt ✗
- **Plac Zamkowy**: *plaques and memorial stones:* 1
- **Podwale**: *plaques and memorial stones:* 1
- **Warecka**: *museums:* Jaskółka ✗; *plaques and memorial stones:* 5
- **Wiślana**: *plaques and memorial stones:* 1
- **Wojciecha Górskiego**: *plaques and memorial stones:* 2
- **Świętokrzyska**: *monuments:* Powstali ○ in game

### Powiśle (56 places)

- **Wybrzeże Kościuszkowskie**: **#15 Most Świętokrzyski** ◐; **#16 Centrum Nauki Kopernik and Planetarium** ★; **#31 Pomnik Syreny nad Wisłą** ◐; **#93 The river barges and the marina (Wieczorek, Biała Barka, Marinka, Kaskadka)** ◐; **#94 Bulwary Wiślane: Schodki, the pavilions, the containers** ⏳; Dworzec Wodny ○ in game; Marina Warszawa (boat) ○ in game; Pawilon 512 ✗; Pracownia Przewrotu Kopernikańskiego ✗; *monuments:* 105 Rocznica Powstania ZNP ○ in game, Rockspinner ✗, Spragniony ○ in game, Syrena ✗, Wielka waga ✗; *bars:* BarKa ✗, Ivy Lounge ✗, Kalima ✗, Kandela Bar ✗, La Vinotheque ✗, Plac Zabaw nad Wisłą ✗, Schodki ⏳, Wir ✗, Wynurzenie ✗; *stages:* Teatr Ateneum - Scena 20 ✗; *hotels:* Sava Boutique Hotel ✗; *plaques and memorial stones:* 5
- **Dobra**: **#17 Biblioteka Uniwersytecka (BUW) and its roof garden** ★; **#55 Elektrownia Powiśle** ◐; Bella Italia (shop) ✗; Kamienica Jana Struskiego (flats) ✗; Młodsza Siostra (shop) ✗; Pawilon Tańca ✗; Wydział "Artes Liberales" UW (university) ✗; Wydział Prawa i Administracji UW. Collegium Iuridicum IV (university) ✗; *monuments:* Inca Garcilaso de la Vega ○ in game, Kantata Ewolucji Wszechświata ✗, Ruszt biblioteczny ✗, Szkic sytuacyjny I ○ in game, Szkic sytuacyjny II ○ in game, Szkic sytuacyjny III ○ in game; *bars:* Messa ✗; *plaques and memorial stones:* 5
- **Smolna**: **#147 Młotek (Smolna 8, 1976, Bogusławski and Gniewiewski, 20 storeys, 66 m)** ★; Dworzec PKP Powiśle ○ in game; Klub Bankowca (offices) ✗; XVIII Liceum Ogólnokształcące im. Jana Zamoyskiego (school) ✗; *monuments:* Dowborczykom ○ in game, Nieznanym Mieszkańcom Warszawy ✗, Obrona Warszawy ○ in game; *bars:* Chopin Taras Cafe ✗, Klub Wieżyca ✗; *museums:* Dom Kultury Śródmieście ✗; *plaques and memorial stones:* 6
- **Tamka**: **#110 Zamek Ostrogskich and the Chopin Institute** ◐; Narodowy Instytut Fryderyka Chopina (offices) ○ in game; Parafia Świętej Teresy od Dzieciątka Jezus (church) ○ in game; Hostel Tatamka (hotel) ✗; *monuments:* Klucz wiolinowy ○ in game, Zgrupowanie AK "Krybar" ✗, Złota Kaczka ○ in game; *bars:* Winem Powiśle ✗; *museums:* Muzeum Fryderyka Chopina ✗; *plaques and memorial stones:* 1
- **Topiel**: **#111 Piano House, Cube House, Hortus, Moderna, Dobra and Tamka tenements** ◐
- **Aleja 3 Maja**: Autoreduta Powiśle (shop) ✗; Centrum Handlowe Arkada (shop) ✗; Nordic Park (offices) ✗; Orlen (shop) ✗; *bars:* Karma Crew Warsaw ✗, Przy3maj ✗; *plaques and memorial stones:* 2
- **Zajęcza**: Moderna Powiśle (flats) ○ in game; Barceló (hotel) ✗; Carpathia Office House (offices) ✗; Stacja elektroenergetyczna 110/15 kV „RPZ Warszawa Powiśle” (offices) ✗; *monuments:* Captain America ○ in game; *bars:* Centrala Bar ✗, Champs ✗, Gatsby Warsaw ✗, Kakadu Karaoke ✗
- **Foksal**: Dom Dziennikarza (commercial) ✗; Pawilon wystawowo-konferencyjny SARP (offices) ✗; Pałac Przezdzieckich (government) ✗; *bars:* Piw Paw ✗; *plaques and memorial stones:* 1
- **Frascati**: Biały Pałacyk ✗; Willa Pniewskiego ✗; *museums:* Muzeum Harcerstwa ✗, Muzeum Ziemi PAN ✗; *stages:* Garnizon Sztuki ✗, Studio Buffo ✗
- **Wioślarska**: The Tides (offices) ✗; Warszawskie Towarzystwo Wioślarskie (offices) ✗; *bars:* Przyjaźń ✗, Sen ✗
- **Wiślana**: Bursa Salezjańska dla Młodzieży Męskiej imienia Księdza Siemca (dormitory) ✗; Szary Dom ✗; *plaques and memorial stones:* 1
- **Adama Idźkowskiego**: Pałacyk Simona de Symonowicza (kindergarten) ✗; *monuments:* Płyta Desantu 3 Dywizji Piechoty I Armii WP ○ in game; *bars:* Cud nad Wisłą ✗, Pod Gigantami ✗
- **Browarna**: Dom Księży Misjonarzy św. Wincentego a Paulo ✗; *bars:* Cheers! ✗; *plaques and memorial stones:* 1
- **Emiliana Konopczyńskiego**: Motel One Warsaw-Chopin ✗; *monuments:* Emilian Konopczyński ○ in game; *plaques and memorial stones:* 2
- **Juliana Smulikowskiego**: Związek Nauczycielstwa Polskiego (offices) ✗; *museums:* Kwiaciarnia Grafiki ✗; *plaques and memorial stones:* 3
- **Książęca**: Domek Holenderski (house) ✗; Yours House (offices) ✗
- **Ludna**: GfK Polonia (offices) ✗; *monuments:* Ławeczka Jerzego Janickiego ○; *bars:* Przekąski u Romana ✗; *plaques and memorial stones:* 2
- **Oboźna**: Dom Strażaka (offices) ✗; *plaques and memorial stones:* 1
- **Aleja Na Skarpie**: *monuments:* Wygasłe źródełko ✗
- **Aleje Jerozolimskie**: *bars:* Emerald Irish Pub ✗, Luzztro ✗
- **Bednarska**: Wydział Dziennikarstwa, Informacji i Bibliologii (university) ✗
- **Cicha**: *plaques and memorial stones:* 1
- **Czerniakowska**: *museums:* Visual Crafters ✗; *plaques and memorial stones:* 1
- **Czerwonego Krzyża**: *plaques and memorial stones:* 3
- **Dynasy**: Rotunda na Dynasach ✗
- **Elektryczna**: *museums:* Pontiseum ✗
- **Ignacego Potockiego**: *plaques and memorial stones:* 3
- **Leona Kruczkowskiego**: *monuments:* Eliza Orzeszkowa ○ in game; *bars:* Warszawa Powiśle ○ in game; *plaques and memorial stones:* 1
- **Lipowa**: Collegium Iuridicum II (university) ○ in game
- **Marii Konopnickiej**: *plaques and memorial stones:* 1
- **Mieczysława Orłowicza**: Rezydencja Orłowicza (flats) ✗
- **Okólnik**: Gmach Biblioteki Ordynacji Krasińskich (commercial) ✗
- **Rozbrat**: *monuments:* Unity ○ in game
- **Solec**: *bars:* Heritage Shop & Wine ✗, Pod Mosteczkiem ✗; *museums:* Muzeum Azji i Pacyfiku ✗; *plaques and memorial stones:* 1
- **Stefana Jaracza**: *stages:* Ateneum ✗; *hotels:* Logos ✗; *plaques and memorial stones:* 2
- **Szara**: *monuments:* Pamięci Armii Krajowej ○ in game
- **Wiejska**: *bars:* Xoxo ✗; *plaques and memorial stones:* 2
- **Wilanowska**: *monuments:* Ksiądz Józef Stanek ○ in game, Zbigniew Ścibor-Rylski ○ in game; *bars:* Grunt i Woda ✗
- **Zagórna**: *monuments:* Chwała Saperom ○ in game; *bars:* Miami Wars ✗

### Wola (124 places)

- **Aleje Jerozolimskie**: **#9 Warszawa Centralna** ★; **#47 Muzeum Narodowe and Muzeum Wojska Polskiego's yard** ◐; **#62 Centrum LIM (Marriott) and Novotel** ★; **#71 Warszawa Śródmieście, Ochota, Powiśle, Stadion stations** ★; **#89 Hotel Polonia Palace, Radisson Blu Sobieski (Radysław Blu)** ◐; **#91 Bars and clubs with parody names: Lusterko, Smoła, Jasna 0, Lombard, Miłość Hipoteczna, 1499 M2, Plan C, Apteczka, Przegryzki Zagryzki, Kasa Biletowa, Żwir, Bar Pyzowy, Hocki Bloki** ○; **#92 Level 26** ◐; **#125 Equator, Equator II, Brama Zachodnia, Proximo I and II, Crown Square, Prosta Office Center** ✗; **#145 Warszawa Śródmieście WKD and Warszawa Ochota WKD (the WKD commuter line's stops)** ★; **#146 Gmach Banku Gospodarstwa Krajowego** ★; Kamienica Stanisława Rostkowskiego (flats) ✗; Nimbus ✗; *bars:* Level 27 ✗; *plaques and memorial stones:* 1
- **Aleja Jana Pawła II**: **#58 Westfield Arkadia (Arkadka)** ★; **#59 Forest** ★; **#123 Aleja Jana Pawła II's blocks and Kaskada** ○; **#124 Babka Tower, Atrium 2, Intraco Prime, North Gate** ✗; The Westin Warsaw ○ in game; Atrium Centrum ✗; Atrium Plaza ✗; Deloitte House ✗; Life Building ✗; Wise Point ✗; *museums:* Galeria XX1 ✗; *plaques and memorial stones:* 2
- **Grzybowska**: **#57 Browary Warszawskie** ◐; **#61 Wola towers: The Bridge, Generation Park X and Z, Atlas Tower, Pekao Tower, Warsaw Towers** ○; **#129 Platinum Towers, Łucka City, Ilmet, Central Tower, Spektrum, PZU, JM Tower, Chałubińskiego 8, Westynka, Chilton** ○; Biura przy Bramie (offices) ○ in game; Biura przy Warzelni ○ in game; Biura przy Willi ○ in game; Concept Tower ✗; Kamienica Gawłowiczów (flats) ✗; Karolkowa Business Park ✗; Kolmex ✗; Prime Corporate Center ✗; Wydział Ruchu Drogowego Komendy Stołecznej Policji ✗; *monuments:* Mur pamięci ○ in game; *bars:* Asap Club ✗, Browar Warszawski ✗, Nine's Sports Bar ✗, Pistaccio ✗, Savore ✗; *museums:* Muzeum Nurkowania ✗, SOA Gallery ✗; *hotels:* Leonardo Royal Hotel Warsaw ✗, Royal Tulip Warsaw Centre ✗; *plaques and memorial stones:* 5
- **Prosta**: **#56 Fabryka Norblina** ★; **#155 Prosta 32, Prosta 28 and Łucka City (Łucka 15)** ★; Prosta Tower ○ in game; Crown Point (offices) ✗; Mennica Legacy Tower Budynek Zachodni (commercial) ✗; Studio A ✗; *monuments:* Pamięci uciekinierów z getta ○ in game; *bars:* Amare Mio! ✗, Instytut ✗, Piano Bar ✗, Torres Wine Bar ✗, Wiśniewski ✗; *hotels:* Holiday Inn Express Warsaw ✗; *plaques and memorial stones:* 1
- **Plac Mirowski**: **#53 Hala Mirowska and Hala Gwardii** ◐; **#151 Osiedle Za Żelazną Bramą (1965-72, Czyż, Furman, Skopiński, Józefowicz)** ✗; Kamienica Mulmanów (flats) ✗; *monuments:* Feliks "Papa" Stamm ✗; *plaques and memorial stones:* 1
- **Prosta**: **#56 Fabryka Norblina** ★; Crown Point (offices) ✗; Mennica Legacy Tower Budynek Zachodni (commercial) ✗; Prosta Tower ✗; Studio A ✗; *monuments:* Pamięci uciekinierów z getta ○ in game; *bars:* Amare Mio! ✗, Instytut ✗, Piano Bar ✗, Torres Wine Bar ✗, Wiśniewski ✗; *hotels:* Holiday Inn Express Warsaw ✗; *plaques and memorial stones:* 1
- **Chłodna**: **#120 Kamienica pod Zegarem and Chłodna's footbridge memorial (Kładka)** ✗; Kamienica Markowskiego (flats) ✗; Meridian (flats) ✗; *monuments:* Kładka Pamięci ○ in game, Matka Boska Łaskawa ○ in game; *museums:* Fundacja Archeologii Fotografii ✗; *plaques and memorial stones:* 2
- **Przyokopowa**: **#21 Muzeum Powstania Warszawskiego** ★; Proximo II (offices) ✗; Wola Center ✗; *monuments:* Stefan Kuryłowicz ○ in game; *museums:* Muzeum Powstania Warszawskiego ★; *plaques and memorial stones:* 1
- **Towarowa**: **#154 Towarowa 22 (superkwartał on the Dom Słowa Polskiego site)** ◐; Generation Park Z ✗; Moxy Warsaw City (hotel) ✗; Vibe ✗
- **Plac Europejski**: **#6 Warsaw Spire** ★; Bellona (offices) ✗; *plaques and memorial stones:* 1
- **Okopowa**: **#134 Klif** ✗
- **Żelazna**: Modsen ○ in game; Dom Kereta ✗; Feniks (commercial) ✗; Kamienica "Pod Strzelcem" (flats) ✗; Kamienica Partowicza (flats) ✗; SwedeCenter ✗; Wojewódzka Stacja Sanitarno-Epidemiologiczna ✗; Zgromadzenie Sióstr Franciszkanek Rodziny Maryi (religious) ✗; *bars:* Estry ✗; *plaques and memorial stones:* 4
- **Nowogrodzka**: Kościół parafialny pw. Dzieciątka Jezus (church) ◐ model; Dom Księdza Boduena ✗; Muzeum Wodociągów i Kanalizacji ✗; Ośrodek Edukacji Informatycznej i Zastosowań Komputerów (university) ✗; Placówka opiekuńczo-wychowawcza "Bajkowy Dworek" ✗; Warszawskie Centrum Zdrowia (shop) ✗; *monuments:* Sokrates Starynkiewicz ○ in game; *bars:* 147 Break ✗; *museums:* Niewidzialna Wystawa ✗
- **Aleja „Solidarności”**: Chronos ✗; Kamienica Jabłońskiego ✗; Sąd Okręgowy w Warszawie (offices) ✗; Willa Natalia (flats) ✗; *bars:* Win ✗; *plaques and memorial stones:* 3
- **Wronia**: Hilton Warsaw City ○ in game; Bar a Boo (shop) ✗; Office House ✗; Oxygen (flats) ✗; *murals:* Boskie Matki ✗, Światowy Dzień Oceanów 2017 ✗
- **Łucka**: Platinum Tower A (flats) ○ in game; Platinum Tower B (flats) ○ in game; Cosinus (school) ✗; Studio B ✗; *bars:* Gimlet ✗, Old Shaker ✗, Pandan ✗, Uwaga Piwo ✗; *museums:* Cosmos Muzeum ✗; *stages:* Kinogram ✗; *malls:* Galeria Platinum Towers ✗; *hotels:* Platinum Residence ✗
- **Chmielna**: HOP (offices) ✗; Kamienica Bagieńskiego (flats) ✗; V Tower ✗; *plaques and memorial stones:* 3
- **Ogrodowa**: City Gate (offices) ✗; Ibis Warszawa Centrum ✗; Wojewódzki Fundusz Ochrony Środowiska i Gospodarki Wodnej (offices) ✗; *monuments:* Władysław Bartoszewski ○ in game; *plaques and memorial stones:* 6
- **Sienna**: Kościół Zielonoświątkowy (church) ◐ model; Instytut Pileckiego (offices) ✗; Nowa Sienna Building (offices) ✗; Sienna Center (offices) ✗
- **Skwer Kardynała Stefana Wyszyńskiego**: Kościół pw. Miłosierdzia Bożego i Świętej Faustyny (church) ◐ model; Dom Sióstr Uczennic Boskiego Mistrza (convent) ✗; Katolicka Agencja Informacyjna (commercial) ✗; *monuments:* Św. Faustyna ○ in game
- **Grójecka**: Kościół parafialny pw. Niepokalanego Poczęcia Najświętszej Maryi Panny ✗; Mazowiecki Dom Pogrzebowy (shop) ✗; *bars:* Dekada ✗; *museums:* Struktury Natury ✗; *plaques and memorial stones:* 4
- **Pańska**: Verit (commercial) ○ in game; The Form ✗; *bars:* Arena ✗
- **Twarda**: Holiday Inn Warszawa City Centre ✗; Kamienica Lejba Osnosa (flats) ✗; *plaques and memorial stones:* 1
- **Waliców**: Ibis Styles Warszawa City (hotel) ✗; Kaplica Kościoła Baptystów (chapel) ✗; *bars:* EWNS ✗
- **Złota**: Kamienica Wolfa Krongolda (flats) ✗; Zarząd Dróg Miejskich (government) ✗; *plaques and memorial stones:* 1
- **Biała**: Kościól Św. Karola Boromeusza (church) ◐ model; *plaques and memorial stones:* 1
- **Daleka**: Centrum Zaopatrzenia Fryzjerów (shop) ✗; Salzburg Center ✗
- **Hrubieszowska**: Crown Tower (offices) ✗; Metropoint Office (offices) ✗
- **Icchoka Lejba Pereca**: Apartamenty Pereca (flats) ✗; *plaques and memorial stones:* 1
- **Juliana Ursyna Niemcewicza**: Stacja ozonowania pośredniego „Sokrates” (industrial) ✗; *plaques and memorial stones:* 1
- **Krochmalna**: Rezydencja Krochmalna 44 (flats) ✗; *bars:* Executive Lounge ✗, Veselka ✗; *plaques and memorial stones:* 1
- **Plac Sokratesa Starynkiewicza**: Miejskie Przedsiębiorstwo Wodociągów i Kanalizacji (offices) ✗; *plaques and memorial stones:* 1
- **Raszyńska**: Cartech (industrial) ✗; Ośrodek Edukacji Informatycznej i Zastosowań Komputerów w Warszawie ✗
- **Spiska**: Instytut Edukacji Artystycznej Akademii Pedagogiki Specjalnej (flats) ✗; *monuments:* Maria Grzegorzewska ○ in game; *plaques and memorial stones:* 1
- **Srebrna**: Pałacyk Sikorskiego (public) ✗; *monuments:* Warszawa Główna ✗; *museums:* Muzeum Woli ✗; *plaques and memorial stones:* 2
- **Słupecka**: Polityka (offices) ✗; Sala św. Faustyny (chapel) ✗
- **Tadeusza Joteyki**: Pauza Ochota (flats) ✗; Wojewódzka Stacja Pogotowia Ratunkowego (hospital) ✗
- **Adama Asnyka**: *plaques and memorial stones:* 1
- **Barska**: *plaques and memorial stones:* 1
- **Ciepła**: *plaques and memorial stones:* 1
- **Elektoralna**: *plaques and memorial stones:* 1
- **Filtrowa**: *monuments:* Gabriel Narutowicz ○ in game; *plaques and memorial stones:* 6
- **Jaktorowska**: *monuments:* Janusz Korczak ○
- **Kaliska**: *plaques and memorial stones:* 2
- **Kolejowa**: **#156 19. Dzielnica** ◐; **#157 Towarowa Towers** ◐; **#159 Stacja Muzeum** ◐; **#160 Nocny Targ (Nocny Market)** ◐; *bars:* Odessa ◐ (ODESSKA), Smok ✗, Space Club ✗; *museums:* Pinball Station ◐ (FLIPEROWNIA)
- **Koszykowa**: *plaques and memorial stones:* 1
- **Leszno**: *monuments:* Pomnik Ofiar Rzezi Woli ○
- **Miedziana**: M7 ✗
- **Platynowa**: *hotels:* Campanile ✗, Golden Tulip ✗, Premiere Classe ✗
- **Rondo Ignacego Daszyńskiego**: *hotels:* Crowne Plaza ✗
- **Sękocińska**: Wojskowe Centrum Rekrutacji Warszawa-Ochota (offices) ✗
- **Tarczyńska**: *bars:* Bar Weterana ✗, Drugie Dno ✗; *museums:* Galeria Ta3 ✗; *plaques and memorial stones:* 2
- **Williama Heerleina Lindleya**: *monuments:* Cmentarz Szpitala Dzieciątka Jezus ○ in game
- **Wolska**: *plaques and memorial stones:* 1
- **Żytnia**: *murals:* Dziwisz się? ✗

### Śródmieście Południowe (90 places)

- **Marszałkowska**: **#2 Rotunda** ★; **#3 Domy Towarowe Centrum: Junior, Sawa, Wars** ★; **#4 Muzeum Sztuki Nowoczesnej** ★; **#50 Plac Konstytucji and MDM** ◐; **#51 Kościół Najświętszego Zbawiciela and Plac Zbawiciela** ◐; **#52 Rondo Dmowskiego and Patelnia (Metro Centrum)** ◐; **#90 Plac Defilad's pavilions: Cepelia, Zodiak, Scena Relax** ◐; **#95 Milk bars: Bar Prasowy (Marszałkowska), Bar Familijny (Nowy Świat), Bar Bambino (Krucza), Bar Pod Barbakanem (Mostowa)** ✗; **#137 Ogród Saski, Ogród Krasińskich, Park Ujazdowski** ○; Kamienica Domańskich (flats) ✗; M76 (offices) ✗; *bars:* W Orbicie Słońca ✗, Warmut ✗; *museums:* QueerMuzeum ✗; *stages:* Polonia ◐; *hotels:* Level rooms ✗; *plaques and memorial stones:* 5
- **Emilii Plater**: **#126 Warsaw Corporate Centre, Centrum Giełdowe, Mysia 3, Liberty Corner, Nautilus, Ethos** ✗; **#153 Pawilon Emilia (1970, taken down in the 2010s)** ✗; Komuna Warszawa (school) ✗; Rezydencja Ambasadora Maroka (house) ✗; *monuments:* All The Things ✗; *plaques and memorial stones:* 3
- **Koszykowa**: **#54 Hala Koszyki** ◐; Biblioteka Publiczna m.st. Warszawy (public) ○ in game; Dom Medyków ✗; Gmach Matematyki i Nauk Informacyjnych ✗; Gmach Szkoły Biznesu (university) ✗; Gmach Technologii Chemicznej ✗; Katedra i Zakład Medycyny Sądowej (university) ✗; Klinika Dermatologiczna WUM (university) ✗; Nobu Hotel Warsaw (hotel) ✗; Nowa Kreślarnia (university) ✗; *bars:* BackRoom Bar ✗, Bar Koszyki ✗, Klub Medyka ✗, Machupisko ✗, Sakebar by Nobu ✗, Upper Deck ✗; *plaques and memorial stones:* 12
- **Wspólna**: **#127 Żyletkowiec, Dom Słowa Polskiego, Dom Chłopa, Smyk's corner** ✗; Kościół pw. Świętych Apostołów Piotra i Pawła (church) ◐ model; Hampton by Hilton Warsaw City Centre ✗; Park Avenue ✗; Ufficio Primo (offices) ✗; *monuments:* Batalion AK "Zaremba-Piorun" ✗, Chrystus i Jawnogrzesznica ○ in game; *bars:* Drink Bar ✗; *museums:* Raster ✗
- **Krucza**: **#30 Cedet (Dom Towarowy CDT)** ★; Referat Paszportów nr 1 (flats) ✗; *plaques and memorial stones:* 1
- **Plac Zbawiciela**: **#96 Plan B's corner, Plac Zbawiciela's café row** ○
- **Filtrowa**: Ministerstwo Obrony Narodowej ○ in game; Ambasada Izraela ✗; Focus ✗; Gmach Rektorska 4 ✗; Instytut Techniki Budowlanej ✗; Najwyższa Izba Kontroli ✗; Ośrodek Akademicki "Przy Filtrowej" (dormitory) ✗; Spółdzielnia Budowlano-Mieszkaniowa (offices) ✗; Stołówka Centralna (university) ✗
- **Nowowiejska**: Budynek Starej Kotłowni (university) ✗; Gmach Aerodynamiki (university) ✗; Gmach Elektrotechniki (university) ✗; Gmach Fizyki (university) ✗; Gmach Inżynierii Środowiska (university) ✗; Gmach Mechaniki (university) ✗; Muzeum Politechniki Warszawskiej (university) ✗; Specjalistyczna Przychodnia Lekarska dla Pracowników Wojska ✗; *monuments:* Mieczysław Pożaryski ○ in game; *bars:* Brać Polskie Wina ✗; *stages:* Klub Komediowy ✗; *plaques and memorial stones:* 3
- **Aleja Niepodległości**: Gmach Lotniczy (university) ✗; Gmach Nowy Lotniczy (university) ✗; ITLIMS ✗; Pałacyk Rektorski ✗; Służba Wywiadu Wojskowego (offices) ✗; *monuments:* Ignacemu Mościckiemu ○ in game; *plaques and memorial stones:* 2
- **Piękna**: IPC Business Centre ✗; Stoen Operator ✗; The Nest (offices) ✗; Willa Struvego (offices) ✗; Zaułek Piękna ✗; *bars:* Ragazzi ✗, Łaskawość Tytusa ✗; *museums:* Muzeum Życia w PRL ✗, Rio ✗; *hotels:* Sen Pszczoły ✗; *plaques and memorial stones:* 6
- **Nowogrodzka**: Dom Katolicki "Roma" (commercial) ✗; Dom Parafialny im. Prymasa Tysiąclecia ✗; Prima Court (offices) ✗; RCKiK w Warszawie TO III Warszawa (hospital) ✗; *stages:* Teatr Muzyczny "Roma" ✗
- **Stanisława Noakowskiego**: Budynek Pod Kominem (university) ✗; Gmach Chemii (university) ✗; Instytut Techniki Cieplnej ✗; Wydział Transportu PW ✗; *monuments:* Batalion AK "Golski" ✗; *bars:* Bar a Wino ✗; *stages:* Stand up Lokal ✗; *plaques and memorial stones:* 6
- **Księdza Ignacego Skorupki**: Bankowy Fundusz Gwarancyjny (offices) ✗; Skłot "Przychodnia" (commercial) ✗; Stratos Office Center (offices) ✗; *bars:* Republika Wina ✗; *hotels:* Residence 1898 ✗; *plaques and memorial stones:* 2
- **Mokotowska**: Instytut Adama Mickiewicza (offices) ✗; Mokotowska Square (offices) ✗; Wydział Pedagogiczny UW (university) ✗; *bars:* Charlie ✗, Le Rendez Vous ✗; *stages:* Współczesny ✗; *plaques and memorial stones:* 2
- **Polna**: 2 Społeczne Liceum Ogólnokształcące STO imienia Pawła Jasienicy (school) ✗; Bazar Polna (shop) ✗; Wydział Elektroniki i Technik Informacyjnych (university) ✗; *plaques and memorial stones:* 3
- **Wilcza**: Komenda Rejonowa Policji Warszawa I (public) ✗; Muzeum i Instytut Zoologii PAN (commercial) ✗; Skłot "Syrena" (flats) ✗; *murals:* Miasta dla ludzi ✗; *bars:* Aficionado Room ✗, Gorączka Złota ✗, H.4.0.S ✗, Jassmine ✗, Kita Koguta ✗, Lodi Dodi ✗, Musa ✗, Rausz ✗; *museums:* Centrala ✗, Maison D'Art ✗; *plaques and memorial stones:* 7
- **Aleje Jerozolimskie**: Kamienica Mikołaja Szelechowa (flats) ✗; Nowogrodzka Square ✗; *malls:* Galeria pod Rondem Czterdziestolatka ✗; *plaques and memorial stones:* 3
- **Lwowska**: Gmach Architektury (university) ✗; Norway House (offices) ✗; *monuments:* Bohdan Pniewski ○ in game; *bars:* Beer Station ✗, Buns & Bottles ✗; *museums:* Totu ✗; *plaques and memorial stones:* 7
- **Hoża**: PGE Energetyka Kolejowa (offices) ✗; *bars:* Aura ✗, Pacyfik ✗; *plaques and memorial stones:* 10
- **Jana i Jędrzeja Śniadeckich**: Instytut Matematyczny PAN (offices) ✗; *plaques and memorial stones:* 8
- **Ludwika Waryńskiego**: Polna Corner (offices) ✗; *plaques and memorial stones:* 1
- **Tytusa Chałubińskiego**: Collegium Anatomicum (hospital) ✗; *plaques and memorial stones:* 1
- **Świętej Barbary**: Centrum Systemów Telekomunikacyjnych (offices) ✗; *bars:* Centro ✗; *plaques and memorial stones:* 1
- **Żurawia**: Dom Spółdzielczości Pracy (flats) ✗; *bars:* Soul ✗; *hotels:* SCSK Żurawia ✗; *plaques and memorial stones:* 2
- **Aleja Wyzwolenia**: *bars:* Plan B ○
- **Jaworzyńska**: *plaques and memorial stones:* 1
- **Plac Konstytucji**: *monuments:* Płaskorzeźba "Otwarcie MDM" ✗; *bars:* Leonardo Daj Winko ✗; *museums:* Galeria Test ✗, Warszawskie Obserwatorium Kultury ✗; *hotels:* Hotel MDM ✗; *plaques and memorial stones:* 1
- **Poznańska**: *bars:* Beirut ✗, Kraken ✗, República de San Escobar ✗, VHS ✗; *hotels:* H15 ✗; *plaques and memorial stones:* 1
- **Progi**: *museums:* Muzeum Marii Dąbrowskiej ✗; *plaques and memorial stones:* 1
- **Stefanii Sempołowskiej**: *stages:* Luna ○

### Ujazdów i Łazienki (55 places)

- **Wiejska**: **#42 Sejm and Senat** ◐; **#82 Sheraton Grand Warsaw** ★; **#114 Pomnik Polskiego Państwa Podziemnego i Armii Krajowej, Pomnik Wincentego Witosa, Pomnik Ignacego Daszyńskiego** ○; Kamienica Karskich (offices) ○ in game; *monuments:* Pomnik Państwa Podziemnego i AK ○ in game; *plaques and memorial stones:* 3
- **Aleje Ujazdowskie**: **#112 Kamienica Pod Gigantami, Pałac Pod Karczochem, Kamienica Ławrynowicza and Aleje Ujazdowskie's villas** ✗; **#113 Pomnik Ronalda Reagana, Pomnik Romana Dmowskiego (Plac Na Rozdrożu)** ○; Kamienica Jakuba Lindelfelda ✗; Kamienica Kulkiewicza (offices) ✗; Kamienica Pusłowskiego (flats) ✗; Pałac Karnickich (offices) ✗; Pałac Sobańskich (offices) ✗; Pałacyk Dziewulskich ✗; Willa L. Jaroszczyńskiego ✗; *monuments:* Bojan Penew ○ in game, Dawid ○ in game, Ronald Reagan ○ in game; *bars:* Klub SPATiF ✗; *museums:* Aspekty ✗, Centrum Kultury Filmowej im. Andrzeja Wajdy ✗; *plaques and memorial stones:* 2
- **Jazdów**: **#43 Zamek Ujazdowski** ◐; Główna Biblioteka Lekarska im. Stanisława Konopki ○ in game; Instytut Teatralny im. Z. Raszewskiego ○ in game; Dawna Łaźnia (offices) ✗; Oddział XV Dzienny Psychiatryczny Rehabilitacyjny (hospital) ✗; Rotacyjny Dom Kultury (house) ✗; *monuments:* Ewa ○ in game, Kompozycja ○ in game, Rozkwit ○ in game, Siedząca ○ in game, Szpital Ujazdowski ○ in game; *museums:* Centrum Sztuki Współczesnej ✗, Domek Filmowy ✗; *stages:* U–jazdowski ✗; *plaques and memorial stones:* 13
- **Czerniakowska**: **#116 Pomnik Sapera** ○; *monuments:* Ławeczka Jana Nowaka-Jeziorańskiego ○; *plaques and memorial stones:* 1
- **Górnośląska**: Sejm RP ○ in game; Kamienica Leona Breslauera (flats) ✗; Monkey Love (shop) ✗; Stary Dom Poselski ✗; Yutori ✗; *murals:* Chopin w Warszawie ✗; *plaques and memorial stones:* 3
- **Aleja Róż**: Ambasada Serbii (offices) ✗; Kamienica Szelechowa (government) ✗; Pałacyk Wielopolskich (offices) ✗; Wydział Konsularny Ambasady Czech (commercial) ✗; *monuments:* Ławeczka Henryka Sławika i Józsefa Antalla ○; *plaques and memorial stones:* 4
- **Fryderyka Chopina**: Ambasada Węgier (offices) ✗; Pałacyk Leszczyńskich ✗; Pałacyk Śleszyńskich (commercial) ✗; *monuments:* Gladiator ○ in game, Stefan "Grot" Rowecki ✗; *plaques and memorial stones:* 4
- **Jana Matejki**: Ambasada Kanady Wydział Wizowy i Imigracji (government) ✗; Budynek Komisji Sejmowych ✗; Desa Unicum (commercial) ✗; *monuments:* Georges Clemenceau ○ in game, Perseusz ○ in game; *plaques and memorial stones:* 5
- **Myśliwiecka**: Dom Oficerski Funduszu Kwaterunku Wojskowego (flats) ✗; Oficyna Ermitażu ✗; Polskie Radio ✗; *monuments:* Dąb Pamięci Tadeusza Mazowieckiego ✗, Król Stefan Batory ✗; *bars:* Rezerwat ✗, Źródełko ✗; *plaques and memorial stones:* 1
- **Zagórna**: Matki Bożej Częstochowskiej (church) ◐ model; Ibis Budget Warszawa Centrum (hotel) ✗; Ibis Styles (hotel) ✗; *monuments:* Kotwica z żaglowca szkolnego "Lwów" ○; *plaques and memorial stones:* 3
- **Fabryczna**: Biuro Legia Sekcja Strzelecka (offices) ✗; Strzelnica Legia ✗; *monuments:* Kazimierz Deyna ○ in game; *bars:* Miejsce ✗; *plaques and memorial stones:* 1
- **Frascati**: Dom Poselski (hotel) ✗; Kancelaria Senatu (government) ✗; *monuments:* Francesco Nullo ○ in game
- **Mokotowska**: Kamienica "Krakowiacy i Górale" (shop) ✗; Mokotowska 69 (shop) ✗; *bars:* Grono ✗; *plaques and memorial stones:* 6
- **Przemysłowa**: Kościół Matki Bożej Jerozolimskiej (church) ◐ model; Torwar II (sports hall) ✗; *bars:* Legia Sports Bar ✗; *museums:* Muzeum Legii Warszawa (w remoncie) ✗; *plaques and memorial stones:* 5
- **Aleja Na Skarpie**: Stary Budynek Komisji Sejmowych ✗; *monuments:* Halina Mikołajska ○ in game; *plaques and memorial stones:* 1
- **Piękna**: Willa Raua (government) ✗; *murals:* Mural Franciszka Pieczki ✗
- **Plac Na Rozdrożu**: Rozdroże 1974 (shop) ✗; *monuments:* Roman Dmowski ○ in game, Wojciech Korfanty ○; *bars:* Przejście ✗; *plaques and memorial stones:* 1
- **Świętej Teresy**: Ministerstwo Sprawiedliwości (government) ✗; *monuments:* Jan Rodowicz "Anoda" ○; *museums:* Cele Bezpieki ✗
- **Aleja Armii Ludowej**: *monuments:* Ignacy Daszyński ○ in game; *plaques and memorial stones:* 1
- **Aleja Przyjaciół**: *plaques and memorial stones:* 2
- **Aleja Wyzwolenia**: *museums:* Apteka Sztuki ✗; *plaques and memorial stones:* 2
- **Francesca Nulla**: Wolf Nullo (offices) ✗
- **Profesorska**: Ambasada Tunezji (commercial) ✗
- **Rozbrat**: *plaques and memorial stones:* 2

### poza dzielnicami (41 places)

- **Plac Bankowy**: **#63 Błękitny Wieżowiec and Plac Bankowy** ○; **#64 Plac Bankowy's palaces: Ratusz, Mazowiecki Urząd Wojewódzki, Gmach Giełdy i Banku Polskiego, Arsenał** ★; **#65 Pomnik Juliusza Słowackiego and Pomnik Stefana Starzyńskiego** ★; **#121 Hotel Saski, Pasaż Muranów, the Muranów estate** ✗
- **Plac Zamkowy**: **#10 Zamek Królewski** ⏳; **#11 Kolumna Zygmunta** ◐; **#38 Plac Zamkowy's houses and Mariensztat** ○; **#109 Pałac Pod Blachą and Biblioteka Królewska** ✗
- **Aleja Solidarności**: **#66 Pomnik Bohaterów Warszawy (Nike)** ★; **#87 Park Praski's bear enclosure (Wybieg dla niedźwiedzi)** ✗; **#139 Warszawska Opera Kameralna, Teatr WARSawy, Pałac Ślubów** ✗
- **Plac Piłsudskiego**: **#19 Grób Nieznanego Żołnierza and Plac Piłsudskiego** ◐; **#46 Metropolitan** ◐; **#68 Pomnik Józefa Piłsudskiego, the Smolensk monuments, Pomnik Lecha Kaczyńskiego** ★
- **Plac Krasińskich**: **#22 Pomnik Powstania Warszawskiego** ★; **#79 Pałac Krasińskich and Ogród Krasińskich** ★
- **Plac Małachowskiego**: **#44 Zachęta** ★; **#45 Kościół Świętej Trójcy** ★
- **Łazienkowska**: **#130 Torwar** ✗; **#131 Stadion Leguminy** ◐
- **Aleja Poniatowskiego**: **#14 Most Poniatowskiego (towers and deck)** ★
- **Aleja Zieleniecka**: **#13 Stadion Narodowy** ★
- **Andersa**: **#98 Kina: Muranów, Atlantic, Luna, Kultura, Elektronik, Femina, Kinoteka, Iluzjon (south of the box)** ○
- **Boleść**: **#140 Stara Prochownia, Collegium Nobilium, Klasztor Ojców Dominikanów (Kościół pw. Świętego Jacka)** ◐
- **Chałubińskiego**: **#152 Ministerstwo Komunikacji (today the Ministry of Infrastructure)** ✗
- **Karasia**: **#83 Teatr Polski and Teatr Powszechny** ★
- **Kopernika**: **#150 Drapacz chmur na Kopernika (the Helvetia hotel, 1923-28, Antoni Jawornicki)** ✗
- **Kościelna**: **#115 Pomnik Marii Skłodowskiej-Curie** ○
- **Muranowska**: **#69 Pomnik Poległym i Pomordowanym na Wschodzie** ★
- **Noakowskiego**: **#107 Gmach Główny Politechniki Warszawskiej** ✗
- **Plac Defilad**: **#1 Pałac Kultury i Nauki** ★
- **Plac Powstańców Warszawy**: **#29 Hotel Warszawa (the 1934 Prudential)** ★
- **Plac Teatralny**: **#18 Teatr Wielki and Teatr Narodowy** ◐
- **Plac Żelaznej Bramy**: **#122 Osiedle Za Żelazną Bramą** ◐
- **Rondo Daszyńskiego**: **#60 Rondo Daszyńskiego towers: Warsaw Unit, Skyliner, The Warsaw HUB, Mennica Legacy Tower, Generation Park Y** ★
- **Rondo ONZ**: **#28 Rondo ONZ towers: Q22, Rondo 1, Cosmopolitan, InterContinental, Warsaw Trade Tower** ○
- **Słomińskiego**: **#72 Dworzec Gdański and its metro** ✗
- **Wioślarska**: **#133 WTS DESKA** ◐
- **Wybrzeże Gdańskie**: **#88 Multimedialny Park Fontann** ✗
- **Ząbkowska**: **#85 Koneser and Ząbkowska's tenements** ✗
- **Świętojańska**: **#24 Archikatedra św. Jana** ◐
<!-- streets:end -->
