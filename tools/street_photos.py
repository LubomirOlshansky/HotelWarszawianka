"""Open street-level photos of a place: Mapillary and Panoramax, for modelling and road-object checks.
    python3 -I tools/street_photos.py X Z [--r=40] [--slug=NAME] [--max=12] [--src=mly,pnx] [--list]
    python3 -I tools/street_photos.py --lat=52.2297 --lon=21.0122 ...

X Z are game metres (+x east, +z south; tools/bake_osm.py `project`). Finds the photos taken within
`r` metres, keeps the ones whose camera looks towards the point (within 60 degrees of the bearing
from the camera to it; panoramas always), newest first, at most `max` (mixed sources), and saves
them to refs/<slug>/street/ (gitignored, like every refs/ photo) with a SOURCES.md line per photo:
source, id, page URL, author, licence, date, the camera's spot and heading and its distance to the
point. `--list` only prints them. Without --slug it lists.

Sources (docs/design/road-objects.md 3.2 S5, model-from-photos skill section 1):
- Mapillary (CC BY-SA 4.0): needs MAPILLARY_TOKEN in the environment (a client token from F's free
  Mapillary developer app; never in a file). graph.mapillary.com, images from *.fbcdn.net.
- Panoramax (CC BY-SA 4.0 or etalab-2.0 per photo, as its `license` says): no key. api.panoramax.xyz,
  images from the instance that holds them (panoramax.openstreetmap.fr for most of Warsaw).
Never Google Street View. The photos are evidence for a spec or a verdict: never traced, never shipped.
Standard library only.
"""
import datetime
import json
import math
import os
import sys
import urllib.parse
import urllib.request

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from bake_osm import LAT0, LON0, M_PER_DEG_LAT, M_PER_DEG_LON  # noqa: E402

UA = "AroundWarsaw-street-photos/1.0 (game reference photos)"
FACING = 60.0


def unproject(x, z):
    return LAT0 - z / M_PER_DEG_LAT, LON0 + x / M_PER_DEG_LON


def project(lat, lon):
    return (lon - LON0) * M_PER_DEG_LON, (LAT0 - lat) * M_PER_DEG_LAT


def get_json(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)


def bbox(lat, lon, r):
    dlat, dlon = r / M_PER_DEG_LAT, r / M_PER_DEG_LON
    return lon - dlon, lat - dlat, lon + dlon, lat + dlat


def ms_date(v):
    """Mapillary's captured_at (ms since 1970) as YYYY-MM-DD."""
    try:
        return datetime.datetime.fromtimestamp(int(v) / 1000, datetime.timezone.utc).strftime("%Y-%m-%d")
    except (TypeError, ValueError):
        return str(v or "")[:10]


def mapillary(lat, lon, r):
    token = os.environ.get("MAPILLARY_TOKEN", "")
    if not token:
        print("street_photos: MAPILLARY_TOKEN not set, Mapillary skipped", file=sys.stderr)
        return []
    q = urllib.parse.urlencode({"access_token": token, "bbox": ",".join(f"{v:.6f}" for v in bbox(lat, lon, r)), "limit": 100,
                                "fields": "id,captured_at,compass_angle,computed_compass_angle,geometry,thumb_1024_url,is_pano,creator"})
    out = []
    for f in get_json("https://graph.mapillary.com/images?" + q).get("data", []):
        lo, la = f["geometry"]["coordinates"]
        out.append({"src": "mapillary", "id": f["id"], "lat": la, "lon": lo,
                    "heading": f.get("computed_compass_angle", f.get("compass_angle")), "pano": bool(f.get("is_pano")),
                    "date": ms_date(f.get("captured_at")),
                    "author": (f.get("creator") or {}).get("username", ""), "licence": "CC-BY-SA-4.0",
                    "page": f"https://www.mapillary.com/app/?pKey={f['id']}", "image": f.get("thumb_1024_url", "")})
    return out


def panoramax(lat, lon, r):
    q = urllib.parse.urlencode({"bbox": ",".join(f"{v:.6f}" for v in bbox(lat, lon, r)), "limit": 100})
    out = []
    for f in get_json("https://api.panoramax.xyz/api/search?" + q).get("features", []):
        p = f.get("properties", {})
        lo, la = f["geometry"]["coordinates"]
        self_url = next((link["href"] for link in f.get("links", []) if link.get("rel") == "self"), "")
        out.append({"src": "panoramax", "id": f["id"], "lat": la, "lon": lo, "heading": p.get("view:azimuth"),
                    "pano": "equirectangular" in json.dumps(p.get("pers:interior_orientation", {})),
                    "date": str(p.get("datetime", ""))[:10], "author": p.get("geovisio:producer", ""),
                    "licence": p.get("license", ""), "page": self_url,
                    "image": (f.get("assets", {}).get("sd") or {}).get("href", "")})
    return out


def main():
    args = sys.argv[1:]
    opt = {a.split("=", 1)[0][2:]: (a.split("=", 1)[1] if "=" in a else "1") for a in args if a.startswith("--")}
    pos = [a for a in args if not a.startswith("--")]
    if "lat" in opt:
        lat, lon = float(opt["lat"]), float(opt["lon"])
        x, z = project(lat, lon)
    elif len(pos) == 2:
        x, z = float(pos[0]), float(pos[1])
        lat, lon = unproject(x, z)
    else:
        print(__doc__)
        sys.exit(2)
    r = float(opt.get("r", 40))
    srcs = opt.get("src", "mly,pnx").split(",")
    found = []
    for name, fn in (("mly", mapillary), ("pnx", panoramax)):
        if name in srcs:
            try:
                found += fn(lat, lon, r)
            except Exception as e:  # a source down must not stop the other
                print(f"street_photos: {name} failed: {e}", file=sys.stderr)
    keep = []
    for p in found:
        px, pz = project(p["lat"], p["lon"])
        dist = math.hypot(x - px, z - pz)
        if dist > r:
            continue
        bearing = math.degrees(math.atan2(x - px, -(z - pz))) % 360.0   # compass: 0 north, 90 east
        off = 0.0 if p["heading"] is None else abs((float(p["heading"]) - bearing + 180.0) % 360.0 - 180.0)
        if p["pano"] or (p["heading"] is not None and off <= FACING):
            keep.append(dict(p, dist=round(dist, 1), off=round(off), x=round(px, 1), z=round(pz, 1)))
    keep.sort(key=lambda p: (p["date"], -p["dist"]), reverse=True)
    keep = keep[:int(opt.get("max", 12))]
    print(f"street_photos: {len(found)} photos within {r:.0f} m of ({x:.1f}, {z:.1f}) = {lat:.6f} N {lon:.6f} E, {len(keep)} facing it")
    for p in keep:
        print(f"  {p['src']:9s} {p['date']} {p['dist']:5.1f} m  off {p['off']:3d} deg  {p['author'][:20]:20s} {p['licence']:14s} {p['page']}")
    slug = opt.get("slug", "")
    if not slug or "list" in opt:
        return
    out_dir = os.path.join(ROOT, "refs", slug, "street")
    os.makedirs(out_dir, exist_ok=True)
    lines = []
    for p in keep:
        if not p["image"]:
            continue
        name = f"{p['src'][:3]}_{p['id']}.jpg"
        try:
            req = urllib.request.Request(p["image"], headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=60) as r_, open(os.path.join(out_dir, name), "wb") as f:
                f.write(r_.read())
        except Exception as e:
            print(f"street_photos: {name} not saved: {e}", file=sys.stderr)
            continue
        lines.append(f"- `street/{name}`: {p['src']} {p['page']}, by {p['author'] or 'unknown'}, {p['licence']}, {p['date']}; "
                     f"camera at ({p['x']}, {p['z']}), heading {p['heading']}, {p['dist']} m from the point, {p['off']} deg off")
    with open(os.path.join(out_dir, "SOURCES.md"), "a", encoding="utf-8") as f:
        f.write(f"\n## Street-level photos of ({x:.1f}, {z:.1f}), r {r:.0f} m (tools/street_photos.py)\n" + "\n".join(lines) + "\n")
    print(f"street_photos: saved {len(lines)} to refs/{slug}/street/")
    print(f"push to the shared store: python3 -I tools/refs_store.py push {slug}")


if __name__ == "__main__":
    main()
