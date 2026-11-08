# Small buildings: the thin towers, one by one

F, 2026-11-07: every small OpenStreetMap building with no height tag stood as a thin 14 m windowed block. Each one was researched and is now drawn as what it is (`game/scripts/small_buildings.gd`, data `game/data/small_buildings.json`, written into the map by `tools/building_heights.py`).

How each was identified: its own OSM tags and the tagged map points inside or within 4 m of it (a `highway=elevator` node inside the Ratusz-Arsenał pair, `railway=ventilation_shaft`, `power=substation`, `amenity=waste_disposal`...). Where those said nothing (206 drawn buildings), the GUGiK aerial (0.87 m/px) and up to two Mapillary street photos facing it were checked. `conf` says how sure: high = tags or a clear photo; low = a guess from size and setting, no photo showed it.

| Type | Count | Model |
| --- | --- | --- |
| Unknown (drawn as a plain 3 m shed) | 98 | plain walls, darker base, roof slab |
| Shed / outbuilding | 74 | plain walls, darker base, roof slab |
| Piece of a bigger building (not drawn) | 50 | left out |
| Lift (metro / street, glass) | 36 | glass shaft on a plinth, overhanging roof slab |
| Bin shelter | 33 | slatted walls, flat roof |
| Metro vent box | 20 | stone-clad box, dark grille band, thin cap |
| Shop / café pavilion | 20 | low base, lit glass, sign strip |
| Historic small building | 19 | plain walls, darker base, roof slab |
| Garage | 19 | plain walls, darker base, roof slab |
| Substation | 16 | plain walls, darker base, roof slab |
| Kiosk | 14 | solid base, lit window band, coloured sign strip |
| Canopy on posts | 13 | roof on posts |
| Toilet | 11 | plain walls, darker base, roof slab |
| Houseboat | 9 | dark hull, lit cabin |
| Boathouse | 8 | plain walls, darker base, roof slab |
| Guard booth | 7 | plain walls, darker base, roof slab |
| Monument, well or water point | 5 | plain walls, darker base, roof slab |
| Nothing there (not drawn) | 5 | left out |
| Metro vent tower (louvred) | 5 | slats all the way up |
| Stair or lift head | 2 | plain walls, darker base, roof slab |
| Bus or tram shelter | 1 | roof on posts |
| Metro entrance roof | 1 | roof on posts |
| Chapel / shrine | 1 | walls and a pyramid roof |

## Every building

x z are map metres (outline centre); OSM is the way id.

### Unknown (drawn as a plain 3 m shed) (98)

| x | z | h | conf | source | why | OSM |
| --- | --- | --- | --- | --- | --- | --- |
| -3015 | -1861 | 3.0 | low | aerial + Mapillary | small box in green, photos not conclusive | 243157680 |
| -2409 | -148 |  | low | not drawn |  | 198815024 |
| -2376 | -2260 | 3.0 | low | aerial + Mapillary | tiny box next to brown roof | 913622846 |
| -2375 | -2376 |  | low | not drawn |  | 978152667 |
| -2282 | -2577 |  | low | not drawn |  | 1424488578 |
| -2050 | -1322 | 3.0 | low | aerial + Mapillary | tiny box under trees by road | 151571912 |
| -1942 | 1638 |  | low | not drawn |  | 900345738 |
| -1656 | -1918 |  | low | not drawn |  | 974122100 |
| -1636 | -1757 |  | low | not drawn |  | 331309221 |
| -1559 | -1753 | 3.0 | low | aerial + Mapillary | hexagon in trees, maybe gazebo | 368465564 |
| -1421 | -1139 |  | low | not drawn |  | 956205033 |
| -1210 | -1226 |  | low | not drawn |  | 934657052 |
| -1189 | -1194 | 3.0 | low | aerial + Mapillary | tiny box at building corner | 764638592 |
| -1180 | -1482 |  | low | not drawn |  | 379997095 |
| -1119 | -1137 |  | low | not drawn |  | 934682193 |
| -955 | -236 |  | low | not drawn |  | 221744437 |
| -948 | -500 |  | low | not drawn |  | 397278928 |
| -926 | -1789 |  | low | not drawn |  | 1568915069 |
| -922 | -348 |  | low | not drawn |  | 221774468 |
| -887 | -1737 |  | low | not drawn |  | 1571088397 |
| -859 | -1356 |  | low | not drawn |  | 380002236 |
| -854 | -268 |  | low | not drawn |  | 221788400 |
| -838 | -1203 | 4.0 | low | aerial + Mapillary | L-shaped sliver among trees and buildings | 258620240 |
| -812 | -1871 |  | low | not drawn |  | 196756149 |
| -804 | 183 |  | low | not drawn |  | 903924225 |
| -772 | -1821 |  | low | not drawn |  | 858328567 |
| -740 | -1524 |  | low | not drawn |  | 358095109 |
| -736 | -1662 |  | low | not drawn |  | 196756170 |
| -730 | -1660 |  | low | not drawn |  | 196756201 |
| -718 | -1609 |  | low | not drawn |  | 404050658 |
| -691 | -1113 |  | low | not drawn |  | 718193811 |
| -677 | -1475 |  | low | not drawn |  | 1565617005 |
| -671 | -1568 |  | low | not drawn |  | 1565617004 |
| -659 | -1517 |  | low | not drawn |  | 1571455274 |
| -659 | -1521 |  | low | not drawn |  | 1571455275 |
| -654 | -1489 |  | low | not drawn |  | 1571455265 |
| -650 | -1489 |  | low | not drawn |  | 1571455264 |
| -646 | -1489 |  | low | not drawn |  | 1571455263 |
| -643 | -1489 |  | low | not drawn |  | 1571455262 |
| -639 | -1474 |  | low | not drawn |  | 1565617001 |
| -638 | -1488 |  | low | not drawn |  | 1571455272 |
| -637 | -1568 |  | low | not drawn |  | 1565617007 |
| -636 | -1550 |  | low | not drawn |  | 1571455276 |
| -634 | -1474 |  | low | not drawn |  | 1565617002 |
| -634 | -1488 |  | low | not drawn |  | 1571455273 |
| -629 | -1488 |  | low | not drawn |  | 1571455261 |
| -626 | -1488 |  | low | not drawn |  | 1571455260 |
| -621 | -1488 |  | low | not drawn |  | 1571455259 |
| -617 | -1488 |  | low | not drawn |  | 1571455258 |
| -613 | -1488 |  | low | not drawn |  | 1571455257 |
| -606 | -1598 |  | low | not drawn |  | 1568227635 |
| -600 | -1581 |  | low | not drawn |  | 1568227637 |
| -598 | -1460 |  | low | not drawn |  | 1567703399 |
| -592 | -1560 |  | low | not drawn |  | 1568227636 |
| -592 | -1461 |  | low | not drawn |  | 1567703398 |
| -591 | -1482 |  | low | not drawn |  | 1571455282 |
| -588 | -1499 |  | low | not drawn |  | 1118056735 |
| -485 | -984 |  | low | not drawn |  | 1127846575 |
| -399 | 168 |  | low | not drawn |  | 905975462 |
| 301 | 1404 |  | low | not drawn |  | 194448961 |
| 441 | -729 |  | low | not drawn |  | 1109034648 |
| 582 | 1216 |  | low | not drawn |  | 1474796629 |
| 603 | 436 |  | low | aerial + Mapillary | small footprint in trees at roundabout, nothing visible | 1504351869 |
| 615 | -1769 |  | low | not drawn |  | 1189215067 |
| 705 | -1606 | 4.0 | low | aerial + Mapillary | box hidden under trees | 890831529 |
| 721 | -1605 | 4.0 | low | aerial + Mapillary | box hidden under trees | 890831530 |
| 743 | -1671 | 3.0 | low | aerial + Mapillary | narrow strip in yard | 890831520 |
| 816 | -1597 |  | low | aerial + Mapillary | small footprint in overgrown park lawn, rubble-like, unseen | 1494104648 |
| 818 | -1596 |  | low | aerial + Mapillary | small footprint in overgrown park lawn, rubble-like, unseen | 1494104649 |
| 818 | -1590 |  | low | aerial + Mapillary | small footprint in overgrown park lawn, rubble-like, unseen | 1494104650 |
| 824 | -1591 |  | low | aerial + Mapillary | small footprint in overgrown park lawn, rubble-like, unseen | 1494104651 |
| 849 | -1582 |  | low | aerial + Mapillary | small footprint in overgrown park lawn, rubble-like, unseen | 1494104642 |
| 851 | -1578 |  | low | aerial + Mapillary | small footprint in overgrown park lawn, rubble-like, unseen | 1494104647 |
| 857 | -1578 |  | low | aerial + Mapillary | small footprint in overgrown park lawn, rubble-like, unseen | 1494104646 |
| 861 | -1578 |  | low | aerial + Mapillary | small footprint in overgrown park lawn, rubble-like, unseen | 1494104645 |
| 864 | -1577 |  | low | aerial + Mapillary | small footprint in overgrown park lawn, rubble-like, unseen | 1494104644 |
| 868 | -1575 |  | low | aerial + Mapillary | small footprint in overgrown park lawn, rubble-like, unseen | 1494104643 |
| 873 | -1574 |  | low | aerial + Mapillary | small footprint in overgrown park lawn, rubble-like, unseen | 1494104641 |
| 876 | -1574 |  | low | aerial + Mapillary | small footprint in overgrown park lawn, rubble-like, unseen | 1494104640 |
| 877 | -1768 |  | low | not drawn |  | 318195931 |
| 905 | 1336 |  | low | not drawn |  | 365887343 |
| 982 | -1604 |  | low | not drawn |  | 317517234 |
| 1006 | 1300 |  | low | not drawn |  | 1033873130 |
| 1015 | 1351 |  | low | not drawn |  | 1033873129 |
| 1076 | -1522 |  | low | not drawn |  | 445070330 |
| 1139 | 147 | 3.0 | low | aerial + Mapillary | thin box by path | 864717189 |
| 1465 | -135 | 4.0 | low | aerial + Mapillary | long thin strip beside road, unclear | 303625762 |
| 1681 | 1294 |  | low | not drawn |  | 854697561 |
| 1697 | 255 |  | low | not drawn |  | 303625254 |
| 1832 | 504 |  | low | not drawn |  | 278212326 |
| 1924 | 385 | 3.0 | low | aerial + Mapillary | tiny box by road, photos show only hedge | 498123228 |
| 1925 | 784 | 4.0 | low | aerial + Mapillary | in trees beside bridge ramp | 674918695 |
| 1942 | 759 | 4.0 | low | aerial + Mapillary | in trees beside bridge ramp | 423432581 |
| 1949 | 758 | 3.0 | low | aerial + Mapillary | in trees beside bridge ramp | 423432577 |
| 1950 | 774 | 4.0 | low | aerial + Mapillary | under trees by ramp car park | 423432583 |
| 1954 | 755 | 3.0 | low | aerial + Mapillary | in trees beside bridge ramp | 423432582 |
| 1957 | 767 | 3.0 | low | aerial + Mapillary | in trees beside bridge ramp | 674929320 |
| 2164 | 1024 | 3.0 | low | aerial + Mapillary | by parking, nothing visible | 426918589 |

### Shed / outbuilding (74)

| x | z | h | conf | source | why | OSM |
| --- | --- | --- | --- | --- | --- | --- |
| -3087 | 1026 |  | high | osm tags | addr:city=Warszawa, addr:housenumber=4/6, addr:street=Kolejowa | 977365955 |
| -3070 | -2524 | 2.5 | low | aerial + Mapillary | narrow outbuilding between block and street, unseen | 1507752563 |
| -2791 | 1563 | 2.5 | low | aerial + Mapillary | small box in courtyard greenery, unseen | 907012219 |
| -2732 | -196 | 3 | low | aerial + Mapillary | narrow grey-roof outbuilding in courtyard, no photo | 947203557 |
| -2436 | -186 | 2.5 | low | aerial + Mapillary | tiny box near recycling and parking entrance | 1488382968 |
| -2358 | -2358 | 2.5 | low | aerial + Mapillary | small box against big building edge in green strip | 978152669 |
| -2233 | -1963 | 3 | low | aerial + Mapillary | small box at edge of parking yard | 1334369175 |
| -2215 | -1806 | 3 | low | aerial + Mapillary | narrow structure in trees | 1334577795 |
| -2207 | -2008 | 3 | low | aerial + Mapillary | small box beside stair entrance of estate block | 1334369178 |
| -2200 | -2011 | 3 | low | aerial + Mapillary | small box between estate blocks | 1334369177 |
| -2193 | -328 |  | high | osm tags | building=shed | 1039575117 |
| -2119 | -2074 | 3 | low | aerial + Mapillary | narrow structure in trees | 1335778885 |
| -2113 | -1871 | 3 | low | aerial + Mapillary | narrow structure in trees between blocks | 1334577796 |
| -2060 | 1216 | 3.0 | medium | aerial + Mapillary | small outbuilding in industrial yard | 900170194 |
| -1912 | -15 |  | high | osm tags | building=shed | 1089771570 |
| -1912 | -1774 | 3 | low | aerial + Mapillary | narrow structure in trees | 1337174154 |
| -1878 | -1054 |  | high | osm tags | building=shed | 855186442 |
| -1843 | -1760 | 3 | low | aerial + Mapillary | small box beyond trees; photos show only street | 1337206988 |
| -1834 | 267 | 3 | low | aerial + Mapillary | tiny box in yard behind street trees, not visible in photos | 1092187518 |
| -1805 | 500 | 2.5 | low | aerial + Mapillary | tiny block beside courtyard street; photos show nothing | 1431165506 |
| -1780 | 384 | 2.5 | low | aerial + Mapillary | small courtyard outbuilding between blocks, unseen | 1431654176 |
| -1681 | -1139 | 3.0 | low | aerial + Mapillary | small box beside corner of building | 403176033 |
| -1585 | -1885 | 3 | low | aerial + Mapillary | mid-size roof in courtyard near gate | 1117489929 |
| -1562 | -189 |  | high | osm tags | building=shed | 460286226 |
| -1524 | 995 | 2.5 | low | aerial + Mapillary | tiny footprint in courtyard, no photo | 1426925638 |
| -1523 | -1751 | 3.0 | low | aerial + Mapillary | hut-like patch in dense greenery by pond | 368465563 |
| -1479 | -1783 | 3 | low | aerial + Mapillary | square structure hidden in trees | 1117489913 |
| -1437 | -1988 | 3 | low | aerial + Mapillary | small structure under trees; photos show only street | 1188350607 |
| -1434 | -1843 | 3 | low | aerial + Mapillary | small structure by gate in trees | 1117489927 |
| -1407 | -1424 | 3 | low | aerial + Mapillary | square structure in green courtyard, tree cover | 1112575534 |
| -1347 | -1489 | 3 | low | aerial + Mapillary | long outbuilding under trees beside building | 1112781308 |
| -1344 | -1505 | 3 | low | aerial + Mapillary | small outbuilding beside larger block, trees | 1112781306 |
| -1207 | -1714 |  | high | osm tags | building=shed · near entrance=yes | 1302824706 |
| -1202 | -1090 | 3.0 | low | aerial + Mapillary | small box between trees and buildings | 898500640 |
| -1196 | -1464 | 3.0 | low | aerial + Mapillary | small wedge between buildings | 380000688 |
| -1148 | -1975 | 3.0 | low | aerial + Mapillary | small box in green courtyard | 380902063 |
| -1045 | 1622 | 2.5 | low | aerial + Mapillary | small rectangle on lawn by gate, unseen | 1430571557 |
| -932 | -1782 | 3.0 | low | aerial + Mapillary | tiny box in courtyard green | 255303025 |
| -909 | 1080 | 3 | low | aerial + Mapillary | small box in green courtyard near gate | 1001804103 |
| -907 | -1674 | 3.0 | low | aerial + Mapillary | tiny box in courtyard trees | 255303026 |
| -907 | 1084 | 3 | low | aerial + Mapillary | small box in green courtyard near gate | 1001804104 |
| -781 | -1902 | 2.5 | low | aerial + Mapillary | small outbuilding in courtyard greenery with wicket gate | 1560790041 |
| -690 | 1511 | 3.0 | low | aerial + Mapillary | small box in back-yard lane | 337372667 |
| -433 | 1263 | 3 | low | aerial + Mapillary | narrow outbuilding in courtyard between blocks | 1095276493 |
| 168 | 64 | 2.5 | low | aerial + Mapillary | tiny box in trees near gate, unseen | 1480623821 |
| 172 | 62 | 2.5 | low | aerial + Mapillary | tiny box in trees at gate, unseen | 1480623820 |
| 174 | 65 | 2.5 | low | aerial + Mapillary | tiny box in trees at gate, unseen | 1480623819 |
| 935 | 1117 | 2.5 | low | aerial + Mapillary | small box in courtyard greenery, unseen | 922640465 |
| 984 | -2020 |  | high | osm tags | building=outbuilding | 1462448316 |
| 1012 | -2037 |  | high | osm tags | building=outbuilding | 1462448309 |
| 1253 | 416 | 3.0 | low | aerial + Mapillary | small box under trees | 888765980 |
| 1255 | 419 | 3.0 | low | aerial + Mapillary | small hut visible in park photo | 888765981 |
| 1429 | -159 |  | high | osm tags | building=shed | 769050434 |
| 1476 | 1354 | 3.0 | low | aerial + Mapillary | small grey-roofed box at car park | 854668377 |
| 1628 | -64 |  | high | osm tags | building=shed | 421879830 |
| 1652 | -76 |  | high | osm tags | building=shed · near access=private, barrier=gate | 421879831 |
| 1695 | 1280 | 3.0 | low | aerial + Mapillary | small grey roof by trees | 854697560 |
| 1891 | 1468 | 4.0 | low | aerial + Mapillary | square roof in trees | 854682317 |
| 1916 | 713 | 3.0 | low | aerial + Mapillary | narrow box in allotment-like area | 780990604 |
| 1924 | 754 | 3.0 | low | aerial + Mapillary | small box in green near parking | 889513522 |
| 1969 | -376 |  | high | osm tags | building=shed | 760019801 |
| 2026 | -1704 | 3 | low | aerial + Mapillary | tiny structure in overgrown yard beside private gate | 972282863 |
| 2030 | -1710 | 3 | low | aerial + Mapillary | tiny structure in overgrown yard beside private gate | 972282862 |
| 2035 | -317 |  | high | osm tags | building=shed | 779158349 |
| 2040 | 363 | 2.5 | low | aerial + Mapillary | tiny box in garden | 908886154 |
| 2050 | -1696 | 3 | low | aerial + Mapillary | small structure in trees near gate and street lamp | 972282864 |
| 2057 | 440 | 2.5 | low | aerial + Mapillary | tiny narrow box in garden | 908886151 |
| 2090 | -262 |  | high | osm tags | building=shed | 760031947 |
| 2118 | -20 | 3.0 | low | aerial + Mapillary | narrow box in garden greenery | 495206072 |
| 2122 | 329 | 3 | low | aerial + Mapillary | small rectangle in tree-covered yard | 1072468098 |
| 2141 | 978 |  | high | osm tags | building=shed | 769152350 |
| 2149 | 985 | 3.0 | low | aerial + Mapillary | tiny box in trees near road | 769152351 |
| 2153 | 990 | 3.0 | low | aerial + Mapillary | narrow box at edge of garden | 769152352 |
| 2161 | -79 | 3.0 | low | aerial + Mapillary | narrow box in garden | 495621045 |

### Piece of a bigger building (not drawn) (50)

| x | z | h | conf | source | why | OSM |
| --- | --- | --- | --- | --- | --- | --- |
| -2678 | -848 |  | medium | aerial + Mapillary | tiny building:part on rooftop of building near hackerspace | 1190491484 |
| -2678 | -848 |  | medium | aerial + Mapillary | tiny building:part on rooftop of building near hackerspace | 1190491484 |
| -2678 | -849 |  | medium | aerial + Mapillary | tiny building:part on rooftop of building near hackerspace | 1190492681 |
| -2678 | -848 |  | medium | aerial + Mapillary | tiny building:part on rooftop of building near hackerspace | 1190491483 |
| -2678 | -848 |  | medium | aerial + Mapillary | tiny building:part on rooftop of building near hackerspace | 1190491483 |
| -2678 | -850 |  | medium | aerial + Mapillary | tiny building:part on rooftop of building near hackerspace | 1190492682 |
| -2677 | -849 |  | medium | aerial + Mapillary | tiny building:part on rooftop of building near hackerspace | 1190492678 |
| -2677 | -849 |  | medium | aerial + Mapillary | tiny building:part on rooftop of building near hackerspace | 1190492678 |
| -2677 | -850 |  | medium | aerial + Mapillary | tiny building:part on rooftop of building near hackerspace | 1190491480 |
| -2677 | -850 |  | medium | aerial + Mapillary | tiny building:part on rooftop of building near hackerspace | 1190491480 |
| -2677 | -848 |  | medium | aerial + Mapillary | tiny building:part on rooftop of building near hackerspace | 1190491482 |
| -2677 | -848 |  | medium | aerial + Mapillary | tiny building:part on rooftop of building near hackerspace | 1190491482 |
| -2676 | -848 |  | medium | aerial + Mapillary | tiny building:part on rooftop of building near hackerspace | 1190491481 |
| -2676 | -848 |  | medium | aerial + Mapillary | tiny building:part on rooftop of building near hackerspace | 1190491481 |
| -2676 | -849 |  | medium | aerial + Mapillary | tiny building:part on rooftop of building near hackerspace | 1190492676 |
| -2566 | 174 |  | low | aerial + Mapillary | building:part, low elongated annex in commercial yard near beauty shops | 1039457828 |
| -2517 | -2040 |  | low | aerial + Mapillary | flat grey roof attached to large building at sports track | 1228287003 |
| -2354 | -2336 |  | low | aerial + Mapillary | long thin strip along bright building edge, like a wall or canopy | 978152665 |
| -2313 | -306 |  | low | aerial + Mapillary | thin strip against block wall, unseen | 1104122755 |
| -2169 | 291 |  | medium | aerial + Mapillary | sliver at office building edge by gate | 504082714 |
| -1691 | -1846 |  | low | aerial + Mapillary | building:part in dark shadow beside bigger building, bollards nearby | 1408747397 |
| -1635 | -27 | 4.0 | low | aerial + Mapillary | narrow strip inside dark courtyard of retail block | 463340409 |
| -1507 | 768 | 6.0 | high | aerial + Mapillary | building:part under overhang of large bank building | 237174732 |
| -1463 | 1096 | 6.0 | medium | aerial + Mapillary | narrow L-shape squeezed between Old Town buildings | 244019994 |
| -1230 | 1622 |  | low | aerial + Mapillary | flat grey roof inside courtyard block cluster | 943507680 |
| -1207 | 1638 | 3 | low | aerial + Mapillary | building:part on paved passage between larger buildings | 943507682 |
| -994 | -1434 | 5.0 | medium | aerial + Mapillary | attached to large pale-roofed building | 788004645 |
| -983 | -147 |  | low | aerial + Mapillary | strip in shadow under large building; grey wall at pavement | 1458812229 |
| -943 | 1092 |  | low | aerial + Mapillary | narrow strip squeezed between large buildings | 1108407701 |
| -858 | -1803 |  | medium | aerial + Mapillary | thin strip between Old Town house roofs | 1571123084 |
| -856 | -1802 |  | high | aerial + Mapillary | building:part brick, tiny, among Old Town houses | 1571123085 |
| -755 | -64 | 4 | medium | aerial + Mapillary | narrow strip at colonnade edge of long block, bike parking | 1452725115 |
| -710 | -1163 |  | low | aerial + Mapillary | narrow footprint within dense old-town block; passage photos show walls | 958285832 |
| -633 | -1568 |  | high | aerial + Mapillary | building:part inside big roofed complex, tiny sliver | 1565617006 |
| -615 | -783 | 4.0 | low | aerial + Mapillary | blurry aerial, inside dense blocks | 628930723 |
| -601 | -774 | 4.0 | low | aerial + Mapillary | blurry aerial, inside dense blocks | 628930713 |
| -585 | -1543 |  | high | aerial + Mapillary | building:part sliver on Royal Castle wing | 1568227638 |
| -580 | -503 | 3.0 | medium | aerial + Mapillary | on flat roof of large building | 414779120 |
| -578 | -497 | 3.0 | medium | aerial + Mapillary | on flat roof of large building | 414779119 |
| -540 | -1699 | 5.0 | medium | aerial + Mapillary | abuts larger grey-roofed building | 821982067 |
| -405 | -107 | 4.0 | low | aerial + Mapillary | narrow strip against buildings | 907823802 |
| 268 | 812 |  | medium | aerial + Mapillary | inside shadowed gap abutting big government block | 964367409 |
| 642 | -155 | 4.0 | low | aerial + Mapillary | adjoins red building | 888875149 |
| 812 | 1446 | 4 | low | aerial + Mapillary | tiny square on edge of large building with gate | 1452965414 |
| 876 | 1397 | 4.0 | low | aerial + Mapillary | narrow strip against warehouse | 390507318 |
| 970 | 1327 |  | low | aerial + Mapillary | long narrow strip alongside bigger blue-roof building | 1033873132 |
| 1029 | -3 | 4.0 | low | aerial + Mapillary | beside large building in shadow | 590197794 |
| 1678 | 1344 | 4.0 | low | aerial + Mapillary | touches large white-roofed building | 854700023 |
| 1836 | -1372 |  | low | aerial + Mapillary | irregular strip in industrial yard attached to larger roofs | 1101311041 |
| 2146 | 992 | 5.0 | low | aerial + Mapillary | against red-roofed house | 769152353 |

### Lift (metro / street, glass) (36)

| x | z | h | conf | source | why | OSM |
| --- | --- | --- | --- | --- | --- | --- |
| -2861 | 428 |  | high | osm tags | building=elevator_housing, highway=elevator, indoor=room · near entrance=yes | 329047327 |
| -2846 | 476 |  | high | osm tags | building=elevator_housing, highway=elevator, indoor=room | 329047323 |
| -2785 | 1026 |  | high | osm tags | building=yes · near highway=elevator | 1425791522 |
| -2779 | 420 | 3 | low | aerial + Mapillary | small box near subway entrance, unseen | 470930748 |
| -2777 | 1048 |  | high | osm tags | building=yes · near highway=elevator | 1425791529 |
| -2774 | 391 |  | high | osm tags | building=elevator_housing, highway=elevator, indoor=room · near entrance=yes | 329047322 |
| -2756 | 1110 |  | high | osm tags | building=yes · near highway=elevator | 1425791538 |
| -2741 | 414 |  | high | osm tags | building=elevator_housing, highway=elevator, indoor=room · near amenity=atm, brand=Planet  | 329047321 |
| -2740 | 462 |  | high | osm tags | building=elevator_housing, highway=elevator, indoor=room · near entrance=yes | 329047326 |
| -2307 | -2745 |  | high | osm tags | building=service · near highway=elevator | 1312488771 |
| -2306 | -2762 |  | high | osm tags | building=service, operator=PKP Polskie Linie Kolejowe, operator:short=PKP PLK · near highw | 1312488774 |
| -2166 | -2737 |  | high | osm tags | building=yes · near highway=elevator, level=0;-1 | 1534560133 |
| -2160 | -2757 |  | high | osm tags | building=yes · near highway=elevator, level=0;-1 | 1515453541 |
| -2159 | -2774 |  | high | osm tags | building=yes · near highway=elevator, level=0;-1 | 1515453549 |
| -2007 | -2754 |  | high | osm tags | building=service · near highway=elevator, level=0;1 | 1312488822 |
| -2006 | -2770 |  | high | osm tags | building=service, operator=PKP Polskie Linie Kolejowe, operator:short=PKP PLK · near highw | 1312488821 |
| -1952 | -2690 |  | high | osm tags | building=yes · near highway=elevator | 1424628476 |
| -1920 | -2744 |  | high | osm tags | building=yes · near highway=elevator | 1424628460 |
| -1889 | -2660 |  | high | osm tags | building=yes · near highway=elevator | 1424628446 |
| -1521 | -1167 |  | high | osm tags | building=service · near highway=elevator, level=0;-1 | 1408288367 |
| -1516 | -1157 |  | high | osm tags | building=service · near highway=elevator, level=0;-1 | 1408288366 |
| -835 | -567 |  | high | osm tags | building=elevator_housing · near highway=elevator, level=-1;0 | 1050794359 |
| 12 | -958 |  | high | osm tags | building:part=yes · near access=permissive, door=hinged | 1196076991 |
| 386 | -813 |  | high | osm tags | building=elevator_housing · near highway=elevator, level=-1;0 | 866708042 |
| 410 | -835 |  | high | osm tags | building=elevator_housing · near highway=elevator | 866658851 |
| 437 | -616 |  | high | osm tags | building=yes · near highway=elevator | 1535989799 |
| 461 | -780 |  | high | osm tags | building=elevator_housing · near highway=elevator, level=-1;0 | 866658852 |
| 474 | -619 |  | high | osm tags | building=elevator_housing · near entrance=yes | 436481330 |
| 481 | -614 | 4 | medium | aerial + Mapillary | elevator tag 7 m; boxy lift pavilion at entrance | 436481329 |
| 558 | -671 |  | high | osm tags | building=elvator_housing · near entrance=yes | 434664547 |
| 566 | -666 | 4 | high | aerial + Mapillary | tagged elevator nearby; glass pavilion at metro entrance | 432807476 |
| 1277 | -1357 |  | high | osm tags | building=elevator, buildingpart=verticalpassage, buildingpart:verticalpassage=elevator · n | 329673191 |
| 1325 | -1367 |  | high | osm tags | building=elvator_housing, buildingpart=verticalpassage, buildingpart:verticalpassage=eleva | 329673190 |
| 1331 | -1466 |  | high | osm tags | building=elvator_housing, buildingpart=verticalpassage, buildingpart:verticalpassage=eleva | 329673189 |
| 1355 | -1309 |  | high | osm tags | building=service · near elevator=yes, highway=elevator | 1344654668 |
| 1368 | -1309 |  | high | osm tags | building=service · near elevator=yes, highway=elevator | 1344654677 |

### Bin shelter (33)

| x | z | h | conf | source | why | OSM |
| --- | --- | --- | --- | --- | --- | --- |
| -3105 | -820 |  | high | osm tags | amenity=waste_disposal, building=yes | 1136162745 |
| -3102 | -622 |  | high | osm tags | amenity=waste_disposal, building=yes | 1136162828 |
| -3088 | -506 |  | high | osm tags | amenity=waste_disposal, building=yes · near natural=tree | 1136176405 |
| -3002 | -674 | 2.5 | low | aerial + Mapillary | small box inside car park | 506175202 |
| -2989 | 1436 | 2.5 | low | aerial + Mapillary | curved small shape by bike racks, bench in courtyard | 1173092099 |
| -2585 | -1101 |  | high | osm tags | access=private, amenity=waste_disposal, building=yes | 1075944663 |
| -2567 | -1064 |  | high | osm tags | access=private, amenity=waste_disposal, building=yes · near amenity=recycling, description | 1075944646 |
| -2485 | -2100 | 2.5 | low | aerial + Mapillary | tiny box at parking edge | 378983933 |
| -2360 | -1544 |  | high | osm tags | amenity=waste_disposal, building=yes · near man_made=carpet_hanger | 1450759967 |
| -2346 | -1613 |  | high | osm tags | amenity=waste_disposal, building=yes | 1450760020 |
| -2292 | -1630 |  | high | osm tags | amenity=waste_disposal, building=yes · near man_made=carpet_hanger | 1450760057 |
| -2279 | -1607 |  | high | osm tags | amenity=waste_disposal, building=yes | 1450760085 |
| -2277 | -1091 | 2.5 | low | aerial + Mapillary | small box on courtyard path between blocks | 1362927968 |
| -2267 | -1591 |  | high | osm tags | amenity=waste_disposal, building=yes · near leaf_type=broadleaved, natural=tree | 1450760087 |
| -2254 | -854 |  | high | osm tags | amenity=waste_disposal, building=yes | 805568615 |
| -2121 | 1037 |  | high | osm tags | access=private, amenity=waste_disposal, building=shed | 986921160 |
| -1840 | -1132 |  | high | osm tags | amenity=waste_disposal, building=yes | 914890702 |
| -1810 | -1826 | 2.5 | low | aerial + Mapillary | small box in courtyard between blocks | 379027465 |
| -1586 | -1068 |  | high | osm tags | access=private, amenity=waste_disposal, building=yes | 1408444817 |
| -1396 | -440 |  | high | osm tags | access=private, amenity=waste_disposal, building=shed | 990304607 |
| -1344 | -1180 |  | high | osm tags | access=private, amenity=waste_disposal, building=yes | 971712930 |
| -1328 | -1536 | 2.5 | low | aerial + Mapillary | small trapezoid near gates and bench in park path | 1112769560 |
| -1203 | 1448 |  | high | osm tags | access=private, amenity=waste_disposal, building=yes | 1104770022 |
| -1195 | 1275 |  | high | osm tags | access=private, amenity=waste_disposal, building=yes · near access=permissive, amenity=bic | 1115005890 |
| -1183 | 1272 |  | high | osm tags | access=private, amenity=waste_disposal, building=yes · near barrier=bollard, bollard=fixed | 1104770018 |
| -1008 | 1437 |  | high | osm tags | building=service · near amenity=waste_basket, material=wood | 1104821178 |
| -436 | -265 |  | high | osm tags | access=private, amenity=waste_disposal, building=garbage_shed | 899022892 |
| -430 | -216 |  | high | osm tags | access=private, amenity=waste_disposal, building=garbage_shed | 415150798 |
| -329 | 127 |  | high | osm tags | access=private, amenity=waste_disposal, building=yes | 1056543616 |
| 325 | -1653 |  | high | osm tags | access=private, amenity=waste_disposal, building=yes | 1009160843 |
| 507 | -1758 |  | high | osm tags | access=private, amenity=waste_disposal, building=service | 443932581 |
| 1185 | -814 |  | high | osm tags | access=private, amenity=waste_disposal, building=yes | 1525875221 |
| 1938 | -233 |  | high | osm tags | amenity=waste_disposal, building=shed · near barrier=gate | 312781857 |

### Metro vent box (20)

| x | z | h | conf | source | why | OSM |
| --- | --- | --- | --- | --- | --- | --- |
| -3085 | 519 |  | high | osm tags | building=service, operator=Metro Warszawskie, railway=ventilation_shaft | 470930737 |
| -3014 | 491 |  | high | osm tags | building=service, railway=ventilation_shaft | 470930745 |
| -2999 | 501 |  | high | osm tags | building=service, railway=ventilation_shaft | 470930740 |
| -2890 | 470 | 4 | high | aerial + Mapillary | grey louvred vent building by Rondo Daszynskiego road | 470930747 |
| -2855 | -525 |  | high | osm tags | building=service, man_made=ventilation_shaft · near natural=tree | 1528246122 |
| -2822 | 437 | 4 | high | aerial + Mapillary | grey vent box with grilles next to tram tracks | 470930749 |
| -1633 | -1376 |  | high | osm tags | building=service, railway=ventilation_shaft | 331003779 |
| -1622 | -1347 |  | high | osm tags | building=service, railway=ventilation_shaft, service=ventilation | 331003777 |
| -1610 | -1329 |  | high | osm tags | building=service, railway=ventilation_shaft, service=ventilation | 331003782 |
| -1151 | 1462 | 4 | medium | aerial + Mapillary | tagged Wentylatornia in courtyard greenery | 1105040302 |
| -1097 | 1484 | 4 | medium | aerial + Mapillary | tagged Wentylatornia; ivy-covered courtyard vent hut | 1105040301 |
| -737 | -181 | 4 | high | aerial + Mapillary | tagged Wentylatornia metra; long strip on boulevard | 647267553 |
| -700 | 996 |  | high | osm tags | building=yes, railway=ventilation_shaft | 271340650 |
| 110 | -479 | 3.5 | low | aerial + Mapillary | same grey vent-box cluster by road, not clearly seen |  |
| 131 | -490 | 3.5 | medium | aerial + Mapillary | grey blocky vent box visible at street edge near crossing |  |
| 1278 | -1325 | 4 | high | aerial + Mapillary | grey stone-clad vent box on grass | 647305904 |
| 1287 | -1274 | 4 | medium | aerial + Mapillary | grey stone-clad box under tree by road | 647305903 |
| 1311 | -1090 | 4 | high | aerial + Mapillary | stone-clad stepped vent/stair housing next to rail | 647305893 |
| 1311 | -1114 | 4 | high | aerial + Mapillary | stone-clad box beside rail embankment, same series | 647305895 |
| 1318 | -1203 | 4 | high | aerial + Mapillary | grey stone-clad box on slope by railway | 647305892 |

### Shop / café pavilion (20)

| x | z | h | conf | source | why | OSM |
| --- | --- | --- | --- | --- | --- | --- |
| -2714 | -754 |  | high | osm tags | building=kiosk, contact:facebook=Warzywniak_uaktora, name=Warzywniak u Aktora · near leaf_ | 1111090580 |
| -2375 | -415 |  | high | osm tags | building=yes, end_date=2012, name=Dom Kereta · near entrance=main | 369781007 |
| -2349 | -1194 |  | high | osm tags | addr:city=Warszawa, addr:housenumber=9A, addr:postcode=01-023 | 1188217298 |
| -1652 | -136 |  | high | osm tags | addr:housenumber=33, addr:street=Grzybowska, building=retail | 467118389 |
| -1557 | -1218 |  | high | osm tags | building=service · near level=-1, name=Franco | 554605389 |
| -1484 | 1556 |  | high | osm tags | access=private, building=yes, leisure=sports_hall | 1468780746 |
| -779 | -1672 |  | high | osm tags | addr:city=Warszawa, addr:city:simc=0918123, addr:housenumber=14 · near name=World of Amber | 404049369 |
| -775 | -1826 |  | high | osm tags | building=apartments, roof:colour=#B26539, roof:material=roof_tiles · near shop=vacant, whe | 356466582 |
| -727 | -1299 |  | high | osm tags | addr:city=Warszawa, addr:city:simc=0918123, addr:housenumber=69 · near amenity=fast_food,  | 328625307 |
| -585 | 555 |  | high | osm tags | building=yes · near amenity=bar, hookah=yes | 1003702499 |
| -486 | 211 |  | high | osm tags | building=retail · near description=sklep czarodziejski, name=Fraida.pl | 327005426 |
| 112 | 1542 |  | high | osm tags | addr:city=Warszawa, addr:city:simc=0918123, addr:housenumber=7 | 462904511 |
| 678 | -567 |  | high | osm tags | building=yes · near amenity=bar, contact:facebook=placzabawnadwisla | 1529205395 |
| 686 | -551 |  | high | osm tags | building=yes · near amenity=fast_food, cuisine=korean | 1529205394 |
| 703 | -532 |  | high | osm tags | building=yes · near amenity=cafe, cuisine=matcha | 1529205392 |
| 704 | -540 |  | high | osm tags | building=yes · near amenity=fast_food, cuisine=pizza | 1529205393 |
| 894 | 132 |  | high | osm tags | building=kiosk | 1208330055 |
| 1164 | 237 |  | high | osm tags | amenity=bar, building=yes, check_date=2026-06-12 | 888765994 |
| 1573 | 1411 |  | high | osm tags | access=customers, addr:city=Warszawa, addr:housenumber=136 | 1065558622 |
| 2108 | 431 | 3.5 | low | aerial + Mapillary | former cafe tag, hidden behind hedge | 498865840 |

### Historic small building (19)

| x | z | h | conf | source | why | OSM |
| --- | --- | --- | --- | --- | --- | --- |
| -2926 | 117 |  | high | osm tags | building=bunker, bunker_type=pillbox, historic=yes | 167109417 |
| -1468 | -620 |  | high | osm tags | building=yes, historic=memorial, memorial=statue | 337848189 |
| -1184 | -1426 |  | high | osm tags | building=summer_house, historic=building, name=Altana ogrodowa | 423475731 |
| -738 | -1633 |  | high | osm tags | building:colour=#af8473, building:material=brick, building:part=yes · near historic=memori | 249227134 |
| -722 | -1615 |  | high | osm tags | building:colour=#af8473, building:material=brick, building:part=yes · near historic=memori | 249227128 |
| -710 | -1141 |  | high | osm tags | building=yes, layer=1 · near artist:wikidata=Q8865537, artist_name=Karol Tchorek | 328625311 |
| 656 | -59 |  | high | osm tags | building=yes, gez:inscription_date=2012-07-24, heritage=2 · near amenity=fast_food, cuisin | 331951388 |
| 664 | -34 |  | high | osm tags | building=yes, gez:inscription_date=2012-07-24, heritage=2 | 331951389 |
| 716 | -79 |  | high | osm tags | building=yes, gez:inscription_date=2012-07-24, heritage=2 · near accor_ticket_acceptant=ye | 331950453 |
| 725 | -54 |  | high | osm tags | building=yes, gez:inscription_date=2012-07-24, heritage=2 | 331950462 |
| 924 | -155 |  | high | osm tags | building=yes, gez:inscription_date=2012-07-24, heritage=2 | 589900430 |
| 927 | -150 |  | high | osm tags | building=yes, gez:inscription_date=2012-07-24, heritage=2 | 331948054 |
| 935 | -124 |  | high | osm tags | building=yes, gez:inscription_date=2012-07-24, heritage=2 · near amenity=pub, name=Pod Mos | 331948055 |
| 936 | -118 |  | high | osm tags | building=yes, gez:inscription_date=2012-07-24, heritage=2 · near amenity=pub, name=Pod Mos | 589900431 |
| 1275 | -1946 |  | high | osm tags | building=yes · near denomination=catholic, historic=wayside_shrine | 1463820515 |
| 1416 | -321 |  | high | osm tags | building=yes, gez:inscription_date=2012-07-24, heritage=2 · near amenity=restaurant, name= | 589204906 |
| 1416 | -315 |  | high | osm tags | building=yes, gez:inscription_date=2012-07-24, heritage=2 · near shop=alcohol | 331948810 |
| 1426 | -285 |  | high | osm tags | building=yes, gez:inscription_date=2012-07-24, heritage=2 · near amenity=pub | 331948809 |
| 1430 | -279 |  | high | osm tags | building=yes, gez:inscription_date=2012-07-24, heritage=2 | 589204912 |

### Garage (19)

| x | z | h | conf | source | why | OSM |
| --- | --- | --- | --- | --- | --- | --- |
| -2642 | -1101 |  | high | osm tags | building=garage | 1075936060 |
| -2640 | -1098 |  | high | osm tags | building=garage | 1075936059 |
| -2639 | -1096 |  | high | osm tags | building=garage | 1075936058 |
| -2637 | -1093 |  | high | osm tags | building=garage | 1075936057 |
| -2327 | -1104 | 3 | low | aerial + Mapillary | small box in courtyard parking area | 1362927976 |
| -2310 | -1115 |  | high | osm tags | addr:city=Warszawa, addr:city:simc=0918123, addr:housenumber=19C | 614827461 |
| -2307 | -1111 |  | high | osm tags | addr:city=Warszawa, addr:city:simc=0918123, addr:housenumber=19D | 614827459 |
| -2306 | -1108 |  | high | osm tags | addr:city=Warszawa, addr:city:simc=0918123, addr:housenumber=19E | 614827457 |
| -2304 | -1105 |  | high | osm tags | addr:city=Warszawa, addr:city:simc=0918123, addr:housenumber=19F | 614827455 |
| -2303 | -1102 |  | high | osm tags | addr:city=Warszawa, addr:city:simc=0918123, addr:housenumber=19G | 614827453 |
| -2247 | -1989 | 3 | low | aerial + Mapillary | small box by parking yard in housing estate | 1334369174 |
| -1379 | -1001 |  | high | osm tags | building=garage | 860252012 |
| -1326 | -1367 |  | high | osm tags | building=garage | 1113133842 |
| -1149 | -1528 | 3.0 | low | aerial + Mapillary | long narrow outbuilding beside block | 380000689 |
| -306 | 177 |  | high | osm tags | building=garage | 905975466 |
| -191 | 1181 | 3 | low | aerial + Mapillary | small box in courtyard strip between rowhouse blocks | 1014265801 |
| -187 | 1211 | 3 | low | aerial + Mapillary | small box in courtyard strip between rowhouse blocks | 1014265800 |
| 2097 | -64 |  | high | osm tags | building=garage | 309630833 |
| 2111 | -452 |  | high | osm tags | building=garage | 492643014 |

### Substation (16)

| x | z | h | conf | source | why | OSM |
| --- | --- | --- | --- | --- | --- | --- |
| -3124 | -1137 |  | high | osm tags | building=yes, frequency=50, location=indoor | 1137307370 |
| -3119 | -1135 |  | high | osm tags | building=service, frequency=50, location=indoor · near natural=tree | 1137307371 |
| -3112 | -2478 |  | high | osm tags | building=service, frequency=50, location=indoor | 1450070686 |
| -2635 | -1233 | 3 | low | aerial + Mapillary | small light-roof box in trees by block | 256923440 |
| -2591 | -1169 |  | high | osm tags | building=service, frequency=50, location=indoor | 320944681 |
| -2376 | -1581 |  | high | osm tags | building=yes, power=substation | 1450760001 |
| -2315 | -1673 |  | high | osm tags | building=yes, power=substation | 383653112 |
| -1898 | 1640 | 3.0 | low | aerial + Mapillary | grey rectangle on lawn edge by road | 900345737 |
| -1380 | -1294 |  | high | osm tags | building=service, frequency=50, location=indoor | 920108716 |
| -964 | -503 |  | high | osm tags | building=service, nohousenumber=yes, power=substation | 397278929 |
| -286 | -1513 |  | high | osm tags | building=service, operator=Stoen Operator, operator:wikidata=Q11833155 · near leaf_type=br | 868059121 |
| -217 | -855 | 3 | low | aerial + Mapillary | blue service box in park, unseen | 62300584 |
| 143 | -1029 |  | high | osm tags | building=service, power=substation, ref=6560 | 867996686 |
| 271 | 7 |  | high | osm tags | building=service, power=substation | 1480623756 |
| 1400 | -1687 |  | high | osm tags | building=service, power=substation | 1295819421 |
| 1494 | -1028 | 4 | low | aerial + Mapillary | square box by industrial wall near road, unclear | 1566437392 |

### Kiosk (14)

| x | z | h | conf | source | why | OSM |
| --- | --- | --- | --- | --- | --- | --- |
| -2642 | -1310 |  | high | osm tags | building=yes, name=Super Warzywko, opening_hours=Mo-Fr 09:00-19:00; Sa 09:00-15:00 | 256922560 |
| -2615 | -1337 | 3 | medium | aerial + Mapillary | disused:shop=kiosk tag; small box beside street, DPD locker nearby | 918603673 |
| -2613 | -1937 |  | high | osm tags | amenity=fast_food, building=retail, check_date=2026-04-04 | 279706502 |
| -1584 | -1274 | 3 | low | aerial + Mapillary | small square in park by bench and bin | 331003780 |
| -1018 | -1852 |  | high | osm tags | addr:city=Warszawa, addr:city:simc=0918123, addr:housenumber=1 | 338647743 |
| -867 | -1754 |  | high | osm tags | building:part=yes, source:geometry=EGiB · near amenity=waste_basket, fixme=Position | 1571088400 |
| -696 | -1243 |  | high | osm tags | amenity=cafe, building=kiosk, check_date=2025-08-11 | 825462224 |
| -676 | -1100 |  | high | osm tags | building=kiosk, check_date=2025-08-11, name=Kołacze | 1029028330 |
| -461 | -595 |  | high | osm tags | amenity=ice_cream, building=kiosk, check_date=2025-08-11 · near currency:PLN=yes, disused: | 825403088 |
| -424 | 950 |  | high | osm tags | building=kiosk | 1190685917 |
| -207 | 363 | 3 | low | aerial + Mapillary | small box on pedestrian street near benches; photos unclear | 1136328647 |
| -155 | 494 | 3.0 | low | aerial + Mapillary | disused retail, small box in square | 240448429 |
| 358 | -270 |  | high | osm tags | building=kiosk · near disused:shop=yes | 1208169412 |
| 623 | -92 |  | high | osm tags | building=retail · near noname=yes, shop=greengrocer | 1208264894 |

### Canopy on posts (13)

| x | z | h | conf | source | why | OSM |
| --- | --- | --- | --- | --- | --- | --- |
| -2867 | 543 |  | high | osm tags | building:part=roof · near amenity=bicycle_parking, bicycle_parking=stands | 1424085645 |
| -1618 | -1837 | 3 | low | aerial + Mapillary | long thin strip along fenced street, bollards nearby | 1117489898 |
| -1569 | 1386 | 3 | low | aerial + Mapillary | thin strip along pavement edge beside building | 1178187587 |
| -1395 | -1399 |  | high | osm tags | building:part=roof | 1192943203 |
| -1321 | -1160 |  | high | osm tags | building:part=roof · near name=Delimaro, opening_hours=Mo-Fr 13:00-18:00 | 1072827827 |
| -874 | -2021 |  | high | osm tags | building:part=roof | 1562728667 |
| -147 | -588 |  | high | osm tags | building:part=roof · near entrance=main | 1251761762 |
| 36 | -1098 | 3.5 | high | aerial + Mapillary | wooden curved-post riverside shelter with benches | 1192417837 |
| 42 | -1090 | 3 | medium | aerial + Mapillary | riverside strip; neighbours show wooden canopy shelters | 1192417834 |
| 48 | -1083 | 3.5 | high | aerial + Mapillary | wooden riverside canopy shelter with scooters | 1192417835 |
| 54 | -1076 | 3 | medium | aerial + Mapillary | riverside strip, same wooden canopy series | 1192417836 |
| 2029 | -1907 | 3 | low | aerial + Mapillary | narrow part along rail platform edge, likely platform roof | 1090506687 |
| 2126 | 1047 |  | high | osm tags | amenity=shelter, bench=yes, building=yes | 426918596 |

### Toilet (11)

| x | z | h | conf | source | why | OSM |
| --- | --- | --- | --- | --- | --- | --- |
| -1901 | 947 |  | high | osm tags | building=toilets, disused:amenity=toilets, location=underground | 1146069071 |
| -1136 | -519 |  | high | osm tags | building=toilets | 1071255414 |
| -650 | -1182 | 3.0 | low | aerial + Mapillary | abandoned toilets tag; long strip, photos show wall | 402416084 |
| 143 | 78 |  | high | osm tags | amenity=toilets, building=yes, check_date=2023-08-04 | 1080806674 |
| 390 | 399 |  | high | osm tags | access=yes, amenity=toilets, building=yes | 1334369423 |
| 1014 | -21 |  | high | osm tags | amenity=toilets, building=yes, charge=1 PLN | 864801335 |
| 1129 | 188 |  | high | osm tags | amenity=toilets, building=yes, charge=1 PLN | 864647737 |
| 1173 | 248 |  | high | osm tags | amenity=toilets, building=yes, check_date=2024-09-06 | 888765996 |
| 1257 | 543 |  | high | osm tags | amenity=toilets, building=toilets, charge=1 PLN | 864567416 |
| 1608 | 86 |  | high | osm tags | building=yes · near access=customers, amenity=toilets | 303625253 |
| 1888 | 611 |  | high | osm tags | amenity=toilets, building=toilets, changing_table=yes | 769101699 |

### Houseboat (9)

| x | z | h | conf | source | why | OSM |
| --- | --- | --- | --- | --- | --- | --- |
| 1544 | 1443 |  | high | osm tags | building=houseboat | 1220123350 |
| 1547 | 1418 |  | high | osm tags | building=houseboat | 1220123349 |
| 1552 | 1467 |  | high | osm tags | building=houseboat | 1220123351 |
| 1558 | 1494 |  | high | osm tags | building=houseboat | 1220123352 |
| 1560 | 1516 |  | high | osm tags | building=houseboat | 1220123353 |
| 1564 | 1532 |  | high | osm tags | building=houseboat | 1220123354 |
| 1566 | 1548 |  | high | osm tags | building=houseboat | 1220123355 |
| 1571 | 1349 |  | high | osm tags | building=houseboat | 1412624940 |
| 1583 | 1372 |  | high | osm tags | building=houseboat | 1412624941 |

### Boathouse (8)

| x | z | h | conf | source | why | OSM |
| --- | --- | --- | --- | --- | --- | --- |
| 500 | -1504 |  | high | osm tags | addr:city=Warszawa, addr:city:simc=0918123, addr:housenumber=8 | 890953720 |
| 504 | -1483 |  | high | osm tags | building=boathouse | 890953721 |
| 544 | -1493 |  | high | osm tags | building=boathouse | 890953722 |
| 560 | -1479 | 3.0 | low | aerial + Mapillary | small box on waterside peninsula | 444955601 |
| 1934 | 800 |  | high | osm tags | building=boathouse | 423432575 |
| 1940 | 811 |  | high | osm tags | building=boathouse | 423432578 |
| 1947 | 818 |  | high | osm tags | building=boathouse | 423432580 |
| 1957 | 840 |  | high | osm tags | building=boathouse | 423432579 |

### Guard booth (7)

| x | z | h | conf | source | why | OSM |
| --- | --- | --- | --- | --- | --- | --- |
| -3116 | 672 | 3 | low | aerial + Mapillary | square roof beside lift gate and gate near school yard | 1351273572 |
| -2877 | -83 |  | high | osm tags | building=guardhouse | 1098918392 |
| -1777 | -308 |  | high | osm tags | building=guardhouse | 1424946686 |
| -1709 | -36 |  | high | osm tags | building=guardhouse · near natural=tree | 462440065 |
| -1606 | -613 |  | high | osm tags | building=guardhouse · near natural=tree | 1145093078 |
| -1578 | 237 |  | high | osm tags | building=gatehouse | 1149290745 |
| -1284 | 1336 | 3 | medium | aerial + Mapillary | small box at campus gate, Politechnika | 271660579 |

### Monument, well or water point (5)

| x | z | h | conf | source | why | OSM |
| --- | --- | --- | --- | --- | --- | --- |
| -2823 | -1404 | 2.5 | low | aerial + Mapillary | oligocene well tag, small box in trees | 430591415 |
| -1799 | -1625 | 1.5 | low | aerial + Mapillary | water_well tag, round footprint in greenery | 152453590 |
| -1587 | -170 | 3.0 | low | aerial + Mapillary | drinking_water tag, octagon in trees | 460252595 |
| 605 | -2010 |  | high | osm tags | building=yes, building:material=wood, fee=no | 1012154009 |
| 1063 | 206 | 1.5 | low | aerial + Mapillary | drinking_water tag, tiny wedge at car park | 886789000 |

### Nothing there (not drawn) (5)

| x | z | h | conf | source | why | OSM |
| --- | --- | --- | --- | --- | --- | --- |
| -2808 | -2771 |  | low | aerial + Mapillary | grassy lot by rail, nothing clear | 294958951 |
| -1913 | 387 |  | low | aerial + Mapillary | abandoned; photo shows only road and corner building, trees on aerial | 982201349 |
| -1214 | -1720 |  | low | aerial + Mapillary | photo shows square and cathedral; only trees at spot | 1117916235 |
| -899 | -56 |  | low | aerial + Mapillary | photo shows glass facade reflection; only thin strip on aerial | 1409403324 |
| 1036 | 1349 |  | low | aerial + Mapillary | photos show trees and road only; tiny strip by gate | 1033632745 |

### Metro vent tower (louvred) (5)

| x | z | h | conf | source | why | OSM |
| --- | --- | --- | --- | --- | --- | --- |
| 1296 | -1456 | 6 | high | aerial + Mapillary | round louvred vent tower, Stadion Narodowy | 678925247 |
| 1296 | -1432 | 6 | high | aerial + Mapillary | round louvred vent tower, Stadion Narodowy | 678925249 |
| 1297 | -1408 | 6 | high | aerial + Mapillary | round louvred vent tower, Stadion Narodowy | 678925248 |
| 1297 | -1384 | 6 | high | aerial + Mapillary | round louvred vent tower, Stadion Narodowy | 678925246 |
| 1298 | -1350 | 5 | high | aerial + Mapillary | tall brown louvred vent tower by road | 647305898 |

### Stair or lift head (2)

| x | z | h | conf | source | why | OSM |
| --- | --- | --- | --- | --- | --- | --- |
| -1294 | 742 | 3 | low | aerial + Mapillary | narrow roof near underground car park entrance, hotel block | 973355140 |
| 1880 | -1848 | 3 | low | aerial + Mapillary | narrow part over rail platform, near underpass stair sign | 1090506672 |

### Bus or tram shelter (1)

| x | z | h | conf | source | why | OSM |
| --- | --- | --- | --- | --- | --- | --- |
| -1271 | 666 | 3 | low | aerial + Mapillary | strip at kerb on avenue median, unclear | 306265045 |

### Metro entrance roof (1)

| x | z | h | conf | source | why | OSM |
| --- | --- | --- | --- | --- | --- | --- |
| 508 | -629 | 3.5 | low | aerial + Mapillary | park plaza by metro entrance, structure unclear | 436481328 |

### Chapel / shrine (1)

| x | z | h | conf | source | why | OSM |
| --- | --- | --- | --- | --- | --- | --- |
| 459 | -2000 | 3.0 | low | aerial + Mapillary | chapel tag, small round plan in courtyard | 699118891 |
