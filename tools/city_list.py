"""Rank the map's landmark candidates (monuments, sculptures, museums, bars, hotels, malls, metro, towers,
office buildings, villas, churches) street by street, most valuable first, with what is done.

Usage (from the repo root; python3 -I tools/city_list.py ...):
    python3 -I tools/city_list.py [--fetch] [--osm docs/inventory/osm_candidates.json] [--out build/city_list.md]

--osm    the OpenStreetMap candidate cache (default docs/inventory/osm_candidates.json, tracked: the
         Overpass result for the map's box with named museums, memorials, statues, art, bars, churches,
         hotels, malls, metro, rail, towers, office buildings, heritage and Wikipedia-tagged objects).
--fetch  refresh that cache from the Overpass API with curl (Apple's python fails the TLS handshake).
--out    the generated markdown (default build/city_list.md, gitignored). docs/CITY_INVENTORY.md is
         the project's list; the inventory thread merges these candidates into it.
Status is a name match against docs/landmarks/specs/*.md, docs/LANDMARKS.md, game/scripts/*.gd and
refs/*/SOURCES.md: a guide, not a proof. Streets come from the nearest named road in
game/map/centrum.json (the baked map is needed). Standard library only.
"""
import json
import math
import os
import re
import sys
import unicodedata
import subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LAT0, LON0 = 52.2340, 21.0240
M_LAT = 110574.0
M_LON = 111320.0 * math.cos(math.radians(LAT0))
BBOX = (52.2183, 20.9780, 52.2595, 21.0565)
QUERY = """[out:json][timeout:180][bbox:%s,%s,%s,%s];
(
 nwr["tourism"~"museum|gallery|artwork|attraction|viewpoint|hotel"]["name"];
 nwr["historic"]["name"];
 nwr["memorial"]["name"];
 nwr["amenity"~"theatre|cinema|bar|pub|nightclub|arts_centre|place_of_worship|library|university|townhall|courthouse|fountain"]["name"];
 nwr["shop"~"mall|department_store"]["name"];
 nwr["building"~"cathedral|church|chapel|synagogue|palace|castle|civic|government|train_station|stadium"]["name"];
 nwr["railway"="station"]["name"];
 nwr["station"="subway"]["name"];
 nwr["railway"="subway_entrance"];
 nwr["wikipedia"]["name"];
 nwr["heritage"]["name"];
 nwr["man_made"~"tower|obelisk"]["name"];
 nwr["building"~"office|commercial"]["name"];
 nwr["office"]["name"]["building"];
 nwr["building"]["name"]["height"~"^(5[5-9]|[6-9][0-9]|[0-9]{3})"];
);
out tags center;
""" % BBOX


def norm(s):
    s = unicodedata.normalize("NFKD", s.lower())
    s = "".join(c for c in s if not unicodedata.combining(c)).replace("ł", "l")
    s = re.sub(r"\b(swietego|swietej|swietych|swietym|swiety|sw)\b\.?", "sw", s)
    s = re.sub(r"\bpw\.?", " ", s)
    s = re.sub(r"[^a-z0-9]+", " ", s)
    return " ".join(s.split())


def project(lat, lon):
    return ((lon - LON0) * M_LON, (LAT0 - lat) * M_LAT)


# Known icons: a name pattern earns +45 and a note on what a player recognises it by.
ICONS = [
    (r"palac kultury", "the tower and spire"), (r"zamek krolewski", "clock tower and brick court"),
    (r"kolumna zygmunta", "the column on its pedestal"), (r"syren", "the sword-and-shield mermaid"),
    (r"stadion narodowy", "the red-white basket"), (r"zlote tarasy", "the glass wave"),
    (r"rotunda", "the round bank"), (r"warszawa centralna", "the glass hall"),
    (r"muzeum sztuki nowoczesnej", "white box and slot"), (r"polin", "glass fins and the canyon"),
    (r"bohaterow getta", "the labradorite wall and relief"), (r"powstania warszawskiego", "the bronze insurgents"),
    (r"nieznanego zolnierza", "the arcade and eternal flame"), (r"maly powstaniec", "the boy in the helmet"),
    (r"warszawska nike", "the winged Nike"), (r"mikolaj kopernik|kopernika", "the seated astronomer"),
    (r"adam mickiewicz", "the poet in bronze"), (r"jan kilinski", "the cobbler with a sabre"),
    (r"poniatowski", "the horseman / the bridge"), (r"varso", "the 310 m tower"),
    (r"warsaw spire", "the three glass towers"), (r"zlota 44", "the sail"), (r"most poniatowskiego", "the arched bridge"),
    (r"teatr wielki", "the colonnade and opera"), (r"kosciol sw anny", "baroque bell tower"),
    (r"archikatedra", "brick Gothic cathedral"), (r"barbakan", "round brick fortification"),
    (r"pomnik chopina|fryderyk chopin", "the willow-bench statue"), (r"lazienki", "palace on the water"),
    (r"palac na wodzie", "palace on the water"), (r"belweder", "yellow palace"), (r"palac prezydencki", "forecourt and lions"),
    (r"hala koszyki", "iron-and-brick hall"), (r"koneser", "red brick vodka factory"),
    (r"patelnia", "the Defilad food court"), (r"tecza", "the rainbow arch"), (r"palma", "the plastic palm"),
    (r"centrum nauki kopernik", "the green roof by the river"), (r"bua|biblioteka uniwersytecka", "the green roof, philosophers"),
    (r"stacja metra|metro", "the M sign"), (r"sejm", "the colonnade"), (r"synagoga nozykow", "the only pre-war synagogue"),
]
FAMOUS_BARS = [
    (r"blikle", "the famous pączek cafe"), (r"wedel", "pijalnia czekolady"), (r"hybrydy", "student club since 1960"),
    (r"tygmont", "jazz club"), (r"plan b", "Plac Zbawiciela bar"), (r"smolna", "the clubs' street"),
    (r"jasna 1", "club"), (r"chlodna 25", "cafe"), (r"bar mleczny", "milk bar"), (r"bar prasowy", "milk bar"),
    (r"pawilony", "bars in the pavilions"), (r"pod retorta|pod gigantami", "old bars"), (r"klub stodola", "club"),
    (r"filtry", "cafe"), (r"harenda", "bar"), (r"lemon", "bar"), (r"kawiarnia literacka", "cafe"),
    (r"bristol", "the hotel's bar"), (r"hard rock", "bar"), (r"mazowiecka 1", "the old cafe"),
    (r"hotel europejski", "grand hotel"), (r"szwajcarska", "cafe"), (r"pijalnia", "cafe"),
]


def category(t):
    n = t.get("name", "")
    nn = norm(n)
    if t.get("station") == "subway" or t.get("subway") == "yes":
        return "metro"
    if t.get("railway") == "station" or t.get("building") == "train_station":
        return "rail"
    if t.get("shop") in ("mall", "department_store"):
        return "mall"
    if t.get("amenity") in ("theatre", "cinema", "arts_centre") or "opera" in nn or "filharmonia" in nn:
        return "culture"
    if t.get("tourism") in ("museum", "gallery") or "muzeum" in nn:
        return "museum"
    if t.get("tourism") == "hotel" or t.get("building") == "hotel":
        return "hotel"
    if t.get("amenity") in ("bar", "pub", "nightclub"):
        return "bar"
    if t.get("memorial") in ("statue", "bust", "sculpture", "stele", "stone", "war_memorial", "obelisk", "cross") \
            or t.get("historic") in ("monument", "memorial", "wayside_shrine", "tomb") \
            or t.get("tourism") == "artwork" or t.get("amenity") == "fountain":
        return "monument"
    if t.get("amenity") == "place_of_worship" or t.get("building") in ("church", "cathedral", "chapel", "synagogue") \
            or re.search(r"koscio|synagog|cerkiew|klasztor|katedr|bazylik|kaplic", nn):
        return "worship"
    if re.search(r"palac|zamek|palacyk|willa|rezydencja|dwor\b", nn) or t.get("building") in ("palace", "castle"):
        return "palace"
    try:
        h = float(str(t.get("height", "0")).split(";")[0].replace("m", "").replace(",", "."))
    except ValueError:
        h = 0
    if h >= 55 or t.get("man_made") == "tower":
        return "tower"
    if t.get("building") in ("office", "commercial") or t.get("office"):
        return "office"
    if re.search(r"kamienica|dom pod|dom bez", nn):
        return "kamienica"
    if t.get("amenity") in ("university", "library", "townhall", "courthouse") or t.get("building") in ("university", "civic", "government"):
        return "civic"
    return "other"


BASE = {"palace": 55, "museum": 50, "culture": 52, "monument": 38, "worship": 36, "tower": 45, "mall": 45,
        "hotel": 26, "metro": 55, "rail": 55, "bar": 24, "kamienica": 30, "office": 28, "civic": 32, "other": 20}
KIND_PL = {"palace": "palace / villa", "museum": "museum / gallery", "culture": "theatre / cinema / music",
           "monument": "monument / sculpture", "worship": "church / religious", "tower": "tower / skyscraper",
           "mall": "mall / department store", "hotel": "hotel", "metro": "metro", "rail": "railway station",
           "bar": "bar / club / pub", "kamienica": "tenement", "office": "office building", "civic": "civic / university", "other": "other"}


def height_of(t):
    try:
        return float(str(t.get("height", "0")).split(";")[0].replace("m", "").replace(",", "."))
    except ValueError:
        return 0.0


def score(t, kind):
    s = BASE[kind]
    nn = norm(t.get("name", ""))
    if "wikipedia" in t:
        s += 22
    if "heritage" in t or "ref:rejestr" in t:
        s += 8
    if t.get("tourism") == "attraction":
        s += 8
    h = height_of(t)
    if kind == "tower":
        s += 25 if h >= 150 else 15 if h >= 100 else 8 if h >= 55 else 0
    for pat, _ in ICONS:
        if re.search(pat, nn):
            s += 45
            break
    if kind == "bar":
        s += 30 if any(re.search(p, nn) for p, _ in FAMOUS_BARS) else 0
        s += 5 if t.get("amenity") == "nightclub" else 0
    if kind == "monument":
        if t.get("tourism") == "artwork" and "wikipedia" not in t:
            s -= 8
        if t.get("memorial") in ("stone", "stele") and "wikipedia" not in t:
            s -= 10
        if t.get("memorial") in ("statue", "bust", "sculpture") and "wikipedia" in t:
            s += 4
    if t.get("office") == "diplomatic":
        s -= 14  # embassies: many, small, mostly villas; kept as texture unless tagged famous
    if kind == "worship" and "wikipedia" not in t:
        s -= 8
    if kind == "kamienica" and "wikipedia" not in t:
        s -= 4
    if kind == "hotel" and re.search(r"sheraton|intercontinental|westin|hilton|marriott|bristol|polonia|europejski|nobu|raffles|sofitel|radisson|mercure|novotel|metropol", nn):
        s += 14
    return s


def tier(s):
    return "S" if s >= 85 else "A" if s >= 65 else "B" if s >= 45 else "C"


def load_text(*patterns):
    out = []
    for p in patterns:
        base = os.path.join(ROOT, p)
        if os.path.isdir(base):
            for fn in sorted(os.listdir(base)):
                if fn.endswith((".md", ".gd", ".json", ".py")):
                    try:
                        out.append(open(os.path.join(base, fn), encoding="utf-8").read())
                    except OSError:
                        pass
        elif os.path.exists(base):
            out.append(open(base, encoding="utf-8").read())
    return norm("\n".join(out))


def refs_text():
    out = []
    rdir = os.path.join(ROOT, "refs")
    if os.path.isdir(rdir):
        for d in sorted(os.listdir(rdir)):
            p = os.path.join(rdir, d, "SOURCES.md")
            if os.path.exists(p):
                out.append(d.replace("_", " ") + " " + open(p, encoding="utf-8").read()[:600])
        idx = os.path.join(rdir, "INDEX.md")
        if os.path.exists(idx):
            out.append(open(idx, encoding="utf-8").read())
    # the shared store (tools/refs_store.py): only the places that have photos there
    sidx = os.path.join(os.environ.get("REFS_STORE") or "/mnt/project-files/refs/", "INDEX.json")
    if os.path.exists(sidx):
        try:
            for x in json.load(open(sidx, encoding="utf-8")).get("inventory", []):
                if x["photos"] + x["street_photos"] + x["more_count"] > 0:
                    out.append(x["place"] + " " + (x["slug"] or "").replace("_", " "))
        except (OSError, ValueError, KeyError):
            pass
    return norm("\n".join(out))


GENERIC = {"kosciol", "sw", "palac", "kamienica", "hotel", "muzeum", "teatr", "pomnik", "dom", "ambasada", "willa",
           "centrum", "plebania", "parafia", "wydzial", "ul", "al", "plac", "park", "skwer", "pawilon", "sklep"}


ALIASES = [
    (r"syrenk", ["syrenka"]), (r"polin|historii zydow", ["polin"]), (r"kolumna zygmunta", ["zygmunt"]),
    (r"stadion narodowy|narodowe centrum sportu", ["stadium"]), (r"centrum nauki kopernik", ["kopernik"]),
    (r"biblioteka uniwersytecka", ["buw"]), (r"muzeum sztuki nowoczesnej", ["msn"]),
    (r"zlote tarasy", ["tarasy"]), (r"palac kultury", ["palace"]), (r"zamek krolewski", ["zamek"]),
    (r"warsaw spire", ["spire"]), (r"zlota 44", ["zlota44"]), (r"teatr wielki", ["teatr wielki"]),
]


def match_in(nn, hay):
    if not nn or len(nn) < 5:
        return False
    for pat, al in ALIASES:
        if re.search(pat, nn):
            return any(a in hay for a in al)
    if nn in hay:
        return True
    words = [w for w in nn.split() if w not in GENERIC]
    key = " ".join(words)
    return len(key) >= 8 and key in hay


def build_street_index(cm):
    cell = 120.0
    segs = {}
    names = []
    for r in cm["roads"]:
        nm = r.get("name")
        if not nm or r.get("k") in ("service", "footway", "path", "cycleway", "track", "steps") or r.get("bridge"):
            continue
        p = r["p"]
        for i in range(0, len(p) - 3, 2):
            x1, z1, x2, z2 = p[i], p[i + 1], p[i + 2], p[i + 3]
            for cx in range(int(min(x1, x2) // cell), int(max(x1, x2) // cell) + 1):
                for cz in range(int(min(z1, z2) // cell), int(max(z1, z2) // cell) + 1):
                    segs.setdefault((cx, cz), []).append((x1, z1, x2, z2, nm))
    return segs, cell


def street_of(segs, cell, x, z):
    best, bn = 1e9, ""
    cx, cz = int(x // cell), int(z // cell)
    for rad in (1, 2, 3):
        for ix in range(cx - rad, cx + rad + 1):
            for iz in range(cz - rad, cz + rad + 1):
                for x1, z1, x2, z2, nm in segs.get((ix, iz), ()):
                    dx, dz = x2 - x1, z2 - z1
                    L = dx * dx + dz * dz
                    t = 0 if L == 0 else max(0, min(1, ((x - x1) * dx + (z - z1) * dz) / L))
                    d = math.hypot(x - (x1 + t * dx), z - (z1 + t * dz))
                    if d < best:
                        best, bn = d, nm
        if best < 60 * rad:
            break
    return bn, best


def main():
    args = sys.argv[1:]
    osm_path = os.path.join(ROOT, "docs", "inventory", "osm_candidates.json")
    out_path = os.path.join(ROOT, "build", "city_list.md")
    if "--osm" in args:
        osm_path = args[args.index("--osm") + 1]
    if "--out" in args:
        out_path = args[args.index("--out") + 1]
    if "--fetch" in args:
        os.makedirs(os.path.dirname(osm_path), exist_ok=True)
        # curl, not urllib: Apple's python fails the Overpass TLS handshake
        subprocess.run(["curl", "-sf", "-m", "240", "-A", "AroundWarsaw-inventory/1.0 (fan game)",
                        "--data-urlencode", "data=" + QUERY, "https://overpass-api.de/api/interpreter", "-o", osm_path], check=True)
    els = json.load(open(osm_path, encoding="utf-8"))["elements"]
    cm = json.load(open(os.path.join(ROOT, "game", "map", "centrum.json"), encoding="utf-8"))
    segs, cell = build_street_index(cm)
    specs = load_text("docs/landmarks/specs", "docs/landmarks")
    landmarks_doc = load_text("docs/LANDMARKS.md")
    code = load_text("game/scripts", "game/data")
    refs = refs_text()
    bx0, bz0, bx1, bz1 = cm["bounds"]

    items, seen = [], set()
    metro_entr = []
    for e in els:
        t = e.get("tags", {})
        c = e.get("center") or ({"lat": e["lat"], "lon": e["lon"]} if "lat" in e else None)
        if not c:
            continue
        x, z = project(c["lat"], c["lon"])
        if not (bx0 <= x <= bx1 and bz0 <= z <= bz1):
            continue
        if t.get("railway") == "subway_entrance":
            metro_entr.append((x, z))
            continue
        name = t.get("name", "").strip()
        if not name or t.get("memorial") == "plaque" or t.get("memorial:type") == "plaque":
            continue
        if t.get("railway") in ("rail", "dismantled", "tram_stop", "halt", "proposed", "abandoned", "disused"):
            continue
        if t.get("amenity") in ("bench", "school", "kindergarten", "enclosing", "parking"):
            continue
        key = (norm(name), round(x / 70), round(z / 70))
        if key in seen:
            continue
        seen.add(key)
        kind = category(t)
        s = score(t, kind)
        nn = norm(name)
        spec = match_in(nn, specs)
        mention = match_in(nn, code) or match_in(nn, landmarks_doc)
        photos = match_in(nn, refs) or (kind != "metro" and any(re.search(pat, nn) and a in refs for pat, a in (("polin|historii zydow", "polin"), ("syrenk", "syren"))))
        st, where = street_of(segs, cell, x, z)
        items.append({"name": name, "kind": kind, "x": round(x), "z": round(z), "street": st or "(no street)",
                      "score": s, "tier": tier(s), "wp": "wikipedia" in t, "spec": spec, "mention": mention,
                      "photos": photos, "tags": t})

    # keep: S/A/B everything, C only for kinds that are the list's point (bars/hotels/tenements stay C and go to counts)
    for it in items:
        if it["kind"] == "metro":
            it["status"] = "partly (entrances modelled, station hall not built)"
        elif it["spec"]:
            it["status"] = "DONE (model + spec)"
        elif it["mention"]:
            it["status"] = "partly (sign, skin or mention)"
        else:
            it["status"] = "open"

    def note(it):
        nn = norm(it["name"])
        for pat, n in ICONS + FAMOUS_BARS:
            if re.search(pat, nn):
                return n
        t = it["tags"]
        bits = []
        if t.get("start_date"):
            bits.append("built " + str(t["start_date"])[:4])
        if t.get("architect"):
            bits.append(str(t["architect"])[:28])
        if t.get("height"):
            bits.append(str(t["height"]).split(";")[0] + " m")
        return ", ".join(bits)

    def row(i, it, with_street=True):
        mark = "x" if it["status"].startswith("DONE") else "~" if it["status"].startswith("partly") else " "
        ph = "photos" if it["photos"] else ""
        cells = [str(i), it["tier"] + str(it["score"]), it["name"].replace("|", "/"), KIND_PL[it["kind"]]]
        if with_street:
            cells.append(it["street"])
        cells += ["(%d, %d)" % (it["x"], it["z"]), "[" + mark + "] " + it["status"], ph, note(it).replace("|", "/")]
        return "| " + " | ".join(cells) + " |"

    items.sort(key=lambda i: (-i["score"], i["name"]))
    n_done = sum(i["status"].startswith("DONE") for i in items)
    n_part = sum(i["status"].startswith("partly") for i in items)
    ct = {}
    for i in items:
        ct.setdefault(i["tier"], [0, 0, 0])
        ct[i["tier"]][0] += 1
        ct[i["tier"]][1] += i["status"].startswith("DONE")
        ct[i["tier"]][2] += i["status"].startswith("partly")

    L = []
    w = L.append
    w("# City list: every landmark worth a model, by street and by value\n")
    w("Generated by `python3 -I tools/city_list.py` (F's ask, 2026-11-02: \"on every street gather the landmarks, "
      "monuments, sculptures, characteristic houses, museums, popular bars, metro, malls, elite houses and skyscrapers; "
      "sorted most valuable to least; what is done, what is not\"). Do not hand-edit the tables: re-run the script after a "
      "landmark lands, then add notes under the section's own heading.\n")
    w("## How to read it\n")
    w("- **Source**: OpenStreetMap (Overpass, one query over the map's box) for names, kinds, Wikipedia and heritage tags; "
      "positions are projected to game x/z; the street is the nearest named road in `game/map/centrum.json`. "
      "%d candidates after dropping plaques, benches and duplicates." % len(items))
    w("- **Value score** = base by kind (palace 55, metro/rail 55, museum 50, culture 52, tower 45, mall 45, monument 38, church 36, "
      "tenement 30, hotel 26, bar 24) + Wikipedia article 22 + heritage 8 + attraction 8 + height + 45 for the known icons "
      "(the `ICONS` list in the script) and 30 for the known bars and cafes. **Tier S** 85+ (a passer-by names it), **A** 65-84 "
      "(a Warsaw person names it), **B** 45-64 (a local knows it), **C** below (texture; shown only as counts).")
    w("- **Status** is a name match against `docs/landmarks/specs/*.md` (DONE: a model with a spec), `game/scripts` and `docs/LANDMARKS.md` "
      "(partly: a sign, a skin, a card or a mention) and `refs/` (photos on the Mac). It misses renamed or parodied items "
      "(the game names some parodies) and can flatter a name that only appears in a comment: check the item's row in `docs/LANDMARKS.md` "
      "before building. Photos column: a refs folder exists; the rest need the model-from-photos skill (Commons photos, GUGiK ortho, spec, Opus acceptance).")
    w("- **Value for the player** is highest where the route goes: Śródmieście, Old Town, Powiśle, Wola business, Praga's river front.\n")
    w("## Totals\n")
    w("| Tier | Items | Done (model+spec) | Partly | Open |\n| --- | --- | --- | --- | --- |")
    for tr in "SABC":
        a = ct.get(tr, [0, 0, 0])
        w("| %s | %d | %d | %d | %d |" % (tr, a[0], a[1], a[2], a[0] - a[1] - a[2]))
    w("| all | %d | %d | %d | %d |\n" % (len(items), n_done, n_part, len(items) - n_done - n_part))
    w("By kind (all tiers): " + "; ".join("%s %d (%d done)" % (KIND_PL[k], sum(i["kind"] == k for i in items),
                                                              sum(i["kind"] == k and i["status"].startswith("DONE") for i in items))
                                          for k in KIND_PL) + ".\n")
    hdr = "| # | Tier+score | Name | Kind | Street | Game x,z | Status | Refs | What it is |\n| --- | --- | --- | --- | --- | --- | --- | --- | --- |"

    top = [i for i in items if i["tier"] in "SA"]
    w("## 1. The whole city, tiers S and A (%d items)\n" % len(top))
    w(hdr)
    for n, it in enumerate(top, 1):
        w(row(n, it))
    w("")

    w("## 2. The next builds: S and A items not done, in order\n")
    w("This is the queue: highest value that is still open or only partly done. One thread per item (docs/WORKFLOW.md).\n")
    w(hdr)
    todo = [i for i in items if i["tier"] in "SA" and not i["status"].startswith("DONE")]
    for n, it in enumerate(todo[:80], 1):
        w(row(n, it))
    w("")

    # specials
    def special(title, kinds, tiers="SABC", limit=60, extra=None, intro=""):
        sel = [i for i in items if i["kind"] in kinds and i["tier"] in tiers]
        if extra:
            sel = [i for i in sel if extra(i)]
        w("## %s (%d)\n" % (title, len(sel)))
        if intro:
            w(intro + "\n")
        w(hdr)
        for n, it in enumerate(sel[:limit], 1):
            w(row(n, it))
        if len(sel) > limit:
            w("\n...and %d more (lower value); run the script with a bigger limit.\n" % (len(sel) - limit))
        w("")

    # metro
    stations = [i for i in items if i["kind"] == "metro"]
    w("## 3. Metro (%d stations in the box)\n" % len(stations))
    w("Entrances are modelled at the real M1/M2 stairs (ROADMAP: vaulted glass canopies, red M posts); the platforms and the station halls "
      "are underground and not built. %d subway entrances are mapped in the box. Status below is for a station building or sign, "
      "not the stairs.\n" % len(metro_entr))
    w(hdr)
    for n, it in enumerate(stations, 1):
        w(row(n, it))
    w("")
    special("4. Malls and department stores", {"mall"})
    special("5. Skyscrapers and towers", {"tower"}, limit=40)
    special("6. Hotels (the grand and the elite ones first)", {"hotel"}, tiers="SAB", limit=40)
    special("7. Monuments, statues, sculptures and memorials", {"monument"}, tiers="SAB", limit=80)
    special("8. Museums, galleries, theatres, cinemas, music", {"museum", "culture"}, tiers="SAB", limit=60)
    special("9. Palaces, villas, residences (the elite houses)", {"palace"}, tiers="SAB", limit=60)
    special("10. Churches, synagogues, monasteries", {"worship"}, tiers="SAB", limit=40)
    special("10b. Office buildings and business centres", {"office"}, tiers="SAB", limit=60,
            intro="Towers over 55 m are in section 5; this is the rest: business centres, headquarters and named office blocks (the Wola and Mokotów business districts, Rondo ONZ, Rondo Daszyńskiego).")
    special("11. Tenements and characteristic houses", {"kamienica"}, tiers="SAB", limit=40)
    special("12. Famous bars, clubs, pubs, cafes", {"bar"}, tiers="ABS", limit=40,
            intro="Only the known names are scored up; the box has %d more named bars and pubs (tier C). Several are already in the game as parodies "
                  "(Lusterko, Smoła, Jasna 0, Lombard, Miłość Hipoteczna, the Zagłębie Kebabowe kebab shops): a real bar keeps its real name only "
                  "when it is a landmark, else a parody (warsaw-tone skill)." % sum(i["kind"] == "bar" and i["tier"] == "C" for i in items))

    # by street
    by = {}
    for i in items:
        by.setdefault(i["street"], []).append(i)
    ranked = sorted(by.items(), key=lambda kv: -sum(i["score"] for i in kv[1] if i["tier"] in "SAB"))
    w("## 13. Street by street\n")
    w("Streets ordered by the value of what stands on them (sum of tier S, A and B scores). Per street: tier S-B items, "
      "most valuable first, with status; tier C is a count. The nearest named road decides the street, so a building behind a "
      "courtyard goes to the street at its front.\n")
    shown = 0
    for st, lst in ranked:
        sab = [i for i in lst if i["tier"] in "SAB"]
        if not sab:
            continue
        shown += 1
        if shown > 90:
            break
        c = sum(1 for i in lst if i["tier"] == "C")
        dn = sum(1 for i in sab if i["status"].startswith("DONE"))
        w("### %s (%d notable, %d done, %d more tier C)\n" % (st, len(sab), dn, c))
        w("| # | Tier | Name | Kind | Game x,z | Status | Refs | What it is |\n| --- | --- | --- | --- | --- | --- | --- | --- |")
        for n, it in enumerate(sab[:30], 1):
            r = row(n, it, with_street=False)
            w(r)
        if len(sab) > 30:
            w("\n...and %d more notable items." % (len(sab) - 30))
        w("")
    w("## 14. How to use this list\n")
    w("1. Take the top open row of section 2 (or the next open row of a street the demo route crosses).\n"
      "2. Run the model-from-photos skill: refs (Commons photos + GUGiK ortho), a spec in `docs/landmarks/specs/`, build, side-by-side check.\n"
      "3. Re-run `python3 -I tools/city_list.py` (needs the baked `centrum.json`) and commit the refreshed list with the model.\n"
      "4. Items the script cannot see: murals, passages, courtyards, pavements and street furniture belong to the street-by-street pass in "
      "`docs/LANDMARKS.md` Map status (\"until it feels alive\").\n")
    open(out_path, "w", encoding="utf-8").write("\n".join(L) + "\n")
    print("wrote", out_path, len(items), "items;", n_done, "done,", n_part, "partly")


if __name__ == "__main__":
    main()
