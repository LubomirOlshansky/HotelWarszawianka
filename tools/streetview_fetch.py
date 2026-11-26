"""Google Street View reference photos for modelling (Static API), saved to refs/ only.
    python3 -I tools/streetview_fetch.py --lat=52.2297 --lon=21.0122 --slug=NAME [--headings=0,90,180,270]
    python3 -I tools/streetview_fetch.py X Z --slug=NAME          (game metres, +x east, +z south)
    python3 -I tools/streetview_fetch.py --address="Marszalkowska 104, Warszawa" --slug=NAME
    python3 -I tools/streetview_fetch.py --building="Ufficio Primo" --slug=NAME [--faces=4] [--spread=40]
          (a name in game/map/centrum.json: one Google panorama out from each long face, three shots
          per face aimed at the face's middle and its two ends, pitch set from the height and distance)
Options: --pitch=5 --fov=90 --size=640x640 --radius=50 --heading-to=LAT,LON (aim one shot at a point)
         --list (metadata only, no image requests) --dry-run (print the URLs without the key, no calls)

Needs GOOGLE_STREETVIEW_KEY in the environment (an environment secret; never in a file, never printed).
For each place it calls the metadata endpoint first (free, no quota use), skips places without
coverage, then fetches one image per heading from that one panorama (pano id, so all headings match)
and saves refs/<slug>/streetview/<pano>_h<heading>.jpg plus a SOURCES.md line: pano id, capture date,
camera spot, heading, pitch, fov. refs/ is gitignored: these are modelling references only,
never committed, shipped, traced or used as textures (model-from-photos skill, F 2026-11-26).
Skips images already saved; refuses more than 8 headings per run (16 images in --building mode).
Panoramas not taken by Google (user photospheres: a park bench, an interior) are skipped: their
copyright is not Google's and they rarely face a building (Ufficio Primo pilot, 2026-11-26). Costs: images are the billable SKU (free monthly tier, then paid); keep headings few.
Standard library only.
"""
import argparse
import json
import math
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
sys.path.insert(0, os.path.join(ROOT, "tools"))
BASE = "https://maps.googleapis.com/maps/api/streetview"
MAX_HEADINGS = 8
MAX_BUILDING_IMAGES = 16
UA = "streetview-fetch/1.0"


def unproject(x, z):
    from bake_osm import LAT0, LON0, M_PER_DEG_LAT, M_PER_DEG_LON
    return LAT0 - z / M_PER_DEG_LAT, LON0 + x / M_PER_DEG_LON


def bearing(la1, lo1, la2, lo2):
    p1, p2, dl = math.radians(la1), math.radians(la2), math.radians(lo2 - lo1)
    y = math.sin(dl) * math.cos(p2)
    x = math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dl)
    return (math.degrees(math.atan2(y, x)) + 360) % 360


def building_faces(name, faces):
    """The `faces` longest sides of the named building's smallest bounding rectangle (centrum.json): for each,
    (mid, a, b, out, length) in game metres, `out` the unit normal away from the building,
    and the building's height. Exits when the name is not found."""
    data = json.load(open(os.path.join(ROOT, "game", "map", "centrum.json")))
    hits = [b for b in data.get("buildings", []) if b.get("name", "").lower() == name.lower()]
    if not hits:
        sys.exit(f"streetview_fetch: no building named {name!r} in game/map/centrum.json")
    b = max(hits, key=lambda b: len(b["p"]))
    p = b["p"]
    ring = list(zip(p[0::2], p[1::2]))
    # The faces are the four sides of the outline's smallest bounding rectangle: a church with an
    # apse, porches and towers has dozens of short edges, but four fronts to look at.
    best = None
    for i in range(len(ring)):
        (x0, z0), (x1, z1) = ring[i], ring[(i + 1) % len(ring)]
        if math.hypot(x1 - x0, z1 - z0) < 1.0:
            continue
        ang = math.atan2(z1 - z0, x1 - x0)
        ca, sa = math.cos(ang), math.sin(ang)
        us = [x * ca + z * sa for x, z in ring]
        vs = [-x * sa + z * ca for x, z in ring]
        area = (max(us) - min(us)) * (max(vs) - min(vs))
        if best is None or area < best[0]:
            best = (area, ca, sa, min(us), max(us), min(vs), max(vs))
    _, ca, sa, u0, u1, v0, v1 = best
    world = lambda u, v: (u * ca - v * sa, u * sa + v * ca)
    uc, vc = (u0 + u1) / 2, (v0 + v1) / 2
    picked = []
    for (u, v, nu, nv, length) in [(uc, v0, 0, -1, u1 - u0), (u1, vc, 1, 0, v1 - v0),
                                   (uc, v1, 0, 1, u1 - u0), (u0, vc, -1, 0, v1 - v0)]:
        mid = world(u, v)
        out = (nu * ca - nv * sa, nu * sa + nv * ca)
        picked.append((mid, None, None, out, length))
    picked.sort(key=lambda e: -e[4])
    picked = picked[:faces]
    return picked, float(b.get("h", 15.0))


def call(path, params, key):
    q = urllib.parse.urlencode({**params, "key": key})
    req = urllib.request.Request(f"{BASE}{path}?{q}", headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=30) as r:
        return r.read(), r.headers.get("Content-Type", "")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("xz", nargs="*", type=float)
    ap.add_argument("--lat", type=float)
    ap.add_argument("--lon", type=float)
    ap.add_argument("--address")
    ap.add_argument("--building")
    ap.add_argument("--faces", type=int, default=4)
    ap.add_argument("--spread", type=float, default=40.0)
    ap.add_argument("--standoff", type=float, default=30.0)
    ap.add_argument("--slug")
    ap.add_argument("--headings", default="0,90,180,270")
    ap.add_argument("--heading-to", dest="heading_to")
    ap.add_argument("--pitch", type=float, default=5)
    ap.add_argument("--fov", type=float, default=90)  # --building mode: use 100 for close fronts
    ap.add_argument("--size", default="640x640")
    ap.add_argument("--radius", type=int, default=50)
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()

    if a.building:
        return building_mode(a)
    if len(a.xz) == 2:
        a.lat, a.lon = unproject(*a.xz)
    if a.address:
        loc = a.address
    elif a.lat is not None and a.lon is not None:
        loc = f"{a.lat:.6f},{a.lon:.6f}"
    else:
        ap.error("give X Z, --lat/--lon or --address")
    key = os.environ.get("GOOGLE_STREETVIEW_KEY", "")
    if not key and not a.dry_run:
        sys.exit("streetview_fetch: GOOGLE_STREETVIEW_KEY not set (environment secret, see docs/design/streetview-setup.md)")

    base = {"location": loc, "radius": a.radius, "source": "outdoor"}
    if a.dry_run:
        print(f"{BASE}/metadata?{urllib.parse.urlencode(base)}&key=<KEY>")
        return
    body, _ = call("/metadata", base, key)
    meta = json.loads(body)
    if meta.get("status") != "OK":
        sys.exit(f"streetview_fetch: no coverage near {loc}: {meta.get('status')} {meta.get('error_message', '')}")
    pano, date, pl = meta["pano_id"], meta.get("date", "?"), meta["location"]
    print(f"pano {pano} captured {date} at {pl['lat']:.6f},{pl['lng']:.6f}")
    if a.list:
        return
    if not a.slug:
        sys.exit("streetview_fetch: --slug is required to save images")

    if a.heading_to:
        tla, tlo = (float(v) for v in a.heading_to.split(","))
        headings = [round(bearing(pl["lat"], pl["lng"], tla, tlo))]
    else:
        headings = [int(float(h)) % 360 for h in a.headings.split(",") if h.strip()]
    if len(headings) > MAX_HEADINGS:
        sys.exit(f"streetview_fetch: {len(headings)} headings, at most {MAX_HEADINGS} per run (each image is a billable request)")
    out = os.path.join(ROOT, "refs", a.slug, "streetview")
    os.makedirs(out, exist_ok=True)
    for h in headings:
        name = f"{pano}_h{h:03d}.jpg"
        if os.path.exists(os.path.join(out, name)):
            print(f"heading {h}: {name} exists, skipped")
            continue
        try:
            data, ctype = call("", {"pano": pano, "size": a.size, "heading": h, "pitch": a.pitch,
                                    "fov": a.fov, "return_error_code": "true"}, key)
        except urllib.error.HTTPError as e:
            print(f"heading {h}: HTTP {e.code}", file=sys.stderr)
            continue
        if not ctype.startswith("image"):
            print(f"heading {h}: not an image ({ctype})", file=sys.stderr)
            continue
        with open(os.path.join(out, name), "wb") as f:
            f.write(data)
        with open(os.path.join(out, "SOURCES.md"), "a") as f:
            f.write(f"- {name}: Google Street View, pano {pano}, captured {date}, camera {pl['lat']:.6f},{pl['lng']:.6f}, "
                    f"heading {h}, pitch {a.pitch:g}, fov {a.fov:g}; reference only, never shipped\n")
        print("saved", os.path.relpath(os.path.join(out, name), ROOT))


def google_pano(lat, lon, radius, key):
    """The nearest Google-taken outdoor panorama within `radius` m, or None (user photospheres
    are skipped: their copyright is not Google's)."""
    for r in (radius, radius * 2):
        body, _ = call("/metadata", {"location": f"{lat:.6f},{lon:.6f}", "radius": r, "source": "outdoor"}, key)
        meta = json.loads(body)
        if meta.get("status") == "OK" and "Google" in meta.get("copyright", ""):
            return meta
    return None


def save_shot(meta, h, pitch, fov, size, slug, key, note=""):
    pano, date, pl = meta["pano_id"], meta.get("date", "?"), meta["location"]
    out = os.path.join(ROOT, "refs", slug, "streetview")
    os.makedirs(out, exist_ok=True)
    name = f"{pano}_h{h:03d}.jpg"
    if os.path.exists(os.path.join(out, name)):
        print(f"heading {h}: {name} exists, skipped")
        return False
    try:
        data, ctype = call("", {"pano": pano, "size": size, "heading": h, "pitch": round(pitch, 1),
                                "fov": fov, "return_error_code": "true"}, key)
    except urllib.error.HTTPError as e:
        print(f"heading {h}: HTTP {e.code}", file=sys.stderr)
        return False
    if not ctype.startswith("image"):
        print(f"heading {h}: not an image ({ctype})", file=sys.stderr)
        return False
    with open(os.path.join(out, name), "wb") as f:
        f.write(data)
    with open(os.path.join(out, "SOURCES.md"), "a") as f:
        f.write(f"- {name}: Google Street View, pano {pano}, captured {date}, camera {pl['lat']:.6f},{pl['lng']:.6f}, "
                f"heading {h}, pitch {pitch:.1f}, fov {fov:g}{note}; reference only, never shipped\n")
    print("saved", os.path.relpath(os.path.join(out, name), ROOT))
    return True


def building_mode(a):
    """One Google panorama out from each of the building's longest faces, three shots per face
    (its middle and both ends), pitch from the height and the distance."""
    if not a.slug:
        sys.exit("streetview_fetch: --slug is required with --building")
    faces, height = building_faces(a.building, a.faces)
    key = os.environ.get("GOOGLE_STREETVIEW_KEY", "")
    if not key and not (a.dry_run or a.list):
        sys.exit("streetview_fetch: GOOGLE_STREETVIEW_KEY not set (environment secret, see docs/design/streetview-setup.md)")
    seen = set()
    count = 0
    for k, (mid, p0, p1, out, length) in enumerate(faces):
        cam = (mid[0] + out[0] * a.standoff, mid[1] + out[1] * a.standoff)
        clat, clon = unproject(*cam)
        print(f"face {k}: {length:.0f} m, facing ({out[0]:+.2f}, {out[1]:+.2f}), camera spot {clat:.6f},{clon:.6f}")
        if a.dry_run or not key:
            continue
        meta = google_pano(clat, clon, a.radius, key)
        if meta is None:
            print(f"face {k}: no Google panorama within {a.radius * 2} m, skipped")
            continue
        pl = meta["location"]
        print(f"face {k}: pano {meta['pano_id']} captured {meta.get('date', '?')} at {pl['lat']:.6f},{pl['lng']:.6f}")
        if meta["pano_id"] in seen or a.list:
            seen.add(meta["pano_id"])
            continue
        seen.add(meta["pano_id"])
        mla, mlo = unproject(*mid)
        # how square-on the panorama sees the face: 0 = straight at it; past 45 degrees the face
        # is hidden or edge-on (a garden, a side street), so its look comes from 3D Tiles instead
        from bake_osm import project
        px, pz = project(pl["lat"], pl["lng"])
        vx, vz = px - mid[0], pz - mid[1]
        off = math.degrees(math.acos(max(-1.0, min(1.0, (vx * out[0] + vz * out[1]) / max(1e-6, math.hypot(vx, vz))))))
        if off > 45.0:
            print(f"face {k}: the panorama sees it {off:.0f} degrees off square, skipped (use 3D Tiles for this face)")
            continue
        dist = max(8.0, math.hypot(pl["lat"] - mla, (pl["lng"] - mlo) * math.cos(math.radians(mla))) * 111320.0)
        pitch = min(35.0, math.degrees(math.atan2(height * 0.55, dist)))
        aim = round(bearing(pl["lat"], pl["lng"], mla, mlo))
        for d in (-a.spread, 0.0, a.spread):
            if count >= MAX_BUILDING_IMAGES:
                sys.exit(f"streetview_fetch: stopped at {MAX_BUILDING_IMAGES} images (each is a billable request)")
            if save_shot(meta, round(aim + d) % 360, pitch, a.fov, a.size, a.slug, key, f", face {k}"):
                count += 1
    print(f"streetview_fetch: {count} images for {a.building}")


if __name__ == "__main__":
    main()
