"""Google Street View reference photos for modelling (Static API), saved to refs/ only.
    python3 -I tools/streetview_fetch.py --lat=52.2297 --lon=21.0122 --slug=NAME [--headings=0,90,180,270]
    python3 -I tools/streetview_fetch.py X Z --slug=NAME          (game metres, +x east, +z south)
    python3 -I tools/streetview_fetch.py --address="Marszalkowska 104, Warszawa" --slug=NAME
Options: --pitch=5 --fov=90 --size=640x640 --radius=50 --heading-to=LAT,LON (aim one shot at a point)
         --list (metadata only, no image requests) --dry-run (print the URLs without the key, no calls)

Needs GOOGLE_STREETVIEW_KEY in the environment (an environment secret; never in a file, never printed).
For each place it calls the metadata endpoint first (free, no quota use), skips places without
coverage, then fetches one image per heading from that one panorama (pano id, so all headings match)
and saves refs/<slug>/streetview/<pano>_h<heading>.jpg plus a SOURCES.md line: pano id, capture date,
camera spot, heading, pitch, fov. refs/ is gitignored: these are modelling references only,
never committed, shipped, traced or used as textures (model-from-photos skill, F 2026-11-26).
Skips images already saved; refuses more than 8 headings per run. Costs: images are the billable SKU (free monthly tier, then paid); keep headings few.
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
UA = "streetview-fetch/1.0"


def unproject(x, z):
    from bake_osm import LAT0, LON0, M_PER_DEG_LAT, M_PER_DEG_LON
    return LAT0 - z / M_PER_DEG_LAT, LON0 + x / M_PER_DEG_LON


def bearing(la1, lo1, la2, lo2):
    p1, p2, dl = math.radians(la1), math.radians(la2), math.radians(lo2 - lo1)
    y = math.sin(dl) * math.cos(p2)
    x = math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dl)
    return (math.degrees(math.atan2(y, x)) + 360) % 360


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
    ap.add_argument("--slug")
    ap.add_argument("--headings", default="0,90,180,270")
    ap.add_argument("--heading-to", dest="heading_to")
    ap.add_argument("--pitch", type=float, default=5)
    ap.add_argument("--fov", type=float, default=90)
    ap.add_argument("--size", default="640x640")
    ap.add_argument("--radius", type=int, default=50)
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()

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


if __name__ == "__main__":
    main()
