#!/usr/bin/env python3
"""Write each street block's eave heights into game/data/street_blocks/index.json.

    python3 -I tools/block_eaves.py [--check]

A street block that keeps LoD2's measured roof (index.json `roof`, landmarks `keeps_lod2_roof`)
draws its own walls from its model and LoD2's roof over them. Where the model's walls stand
taller than the measured roof (78 blocks, 2026-11-19: Al. Jerozolimskie by Nowy Świat and
most of Śródmieście's tenements), the roof sat a storey down inside its own walls, an open
box from above (F's teaser shot). map_builder lifts each kept roof plane to the walls it meets
(`_lift_block_roofs`); this gives it the walls' height: `eaves`, one number per outline edge
(edge i runs from point i to point i + 1, the last back to the first), the height of the
block's wall tops along that edge in metres over the block's ground (the model's own y,
_build_block's `_g`), or null where no wall of the model runs along it. The height is the
edge's lower quartile of the wall tops, so a cornice line, not the pilasters and towers over it.

--check: exit 1 when index.json is not what this would write (CI can run it; it reads only
committed files). Standard library only.
"""
import gzip
import json
import math
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BLOCKS = ROOT / "game" / "data" / "street_blocks"
NEAR = 1.5  # a wall vertex this close to a point on the edge counts for it (m)
STEP = 1.0  # samples along each edge (m)


def walls_of(block_id: str) -> list:
    """The model's wall vertices (x, y, z), y over the block's ground: triangles whose normal is
    more horizontal than _build_block's 0.3 test."""
    raw = gzip.open(BLOCKS / f"{block_id}.bin").read()
    head = struct.unpack("<I", raw[:4])[0]
    d = json.loads(raw[4:4 + head])
    at = 4 + head
    out = []
    for g in d["groups"]:
        n = g["n"]
        if g["role"] != "roof":
            for t in range(n):
                v = struct.unpack("<9h", raw[at + t * 18:at + t * 18 + 18])
                p = [(v[k] * 0.01 + d["ox"], v[k + 1] * 0.01, v[k + 2] * 0.01 + d["oz"]) for k in (0, 3, 6)]
                u = [p[1][i] - p[0][i] for i in range(3)]
                w = [p[2][i] - p[0][i] for i in range(3)]
                nx = u[1] * w[2] - u[2] * w[1]
                ny = u[2] * w[0] - u[0] * w[2]
                nz = u[0] * w[1] - u[1] * w[0]
                ln = math.sqrt(nx * nx + ny * ny + nz * nz)
                if ln > 1e-9 and abs(ny) / ln < 0.3:
                    out.extend(p)
        at += n * 18 + (n if g["role"] == "glass" else 0)
    return out


def eaves_of(entry: dict) -> list:
    o = entry["outline"]
    pts = [(o[i], o[i + 1]) for i in range(0, len(o) - 1, 2)]
    grid: dict = {}
    for x, y, z in walls_of(entry["id"]):
        key = (math.floor(x), math.floor(z))
        grid.setdefault(key, []).append((x, y, z))
    out = []
    for i, (x0, z0) in enumerate(pts):
        x1, z1 = pts[(i + 1) % len(pts)]
        length = math.hypot(x1 - x0, z1 - z0)
        tops = []
        s = min(0.5, length * 0.5)
        while s <= length:
            px = x0 + (x1 - x0) * s / length if length > 0 else x0
            pz = z0 + (z1 - z0) * s / length if length > 0 else z0
            best = None
            for gx in range(math.floor(px - NEAR), math.floor(px + NEAR) + 1):
                for gz in range(math.floor(pz - NEAR), math.floor(pz + NEAR) + 1):
                    for x, y, z in grid.get((gx, gz), ()):
                        if (x - px) ** 2 + (z - pz) ** 2 <= NEAR * NEAR and (best is None or y > best):
                            best = y
            if best is not None:
                tops.append(best)
            s += STEP
        if tops:
            tops.sort()
            out.append(round(tops[(len(tops) - 1) // 4], 1))
        else:
            out.append(None)
    return out


def main() -> int:
    check = "--check" in sys.argv[1:]
    path = BLOCKS / "index.json"
    text = path.read_text()
    blocks = json.loads(text)
    for entry in blocks:
        if entry.get("roof"):
            entry["eaves"] = eaves_of(entry)
        else:
            entry.pop("eaves", None)
    new = json.dumps(blocks, separators=(",", ":"), ensure_ascii=False)
    if check:
        if new != text.rstrip("\n"):
            print("block_eaves: index.json's eaves are stale: run python3 -I tools/block_eaves.py")
            return 1
        print("block_eaves: OK")
        return 0
    path.write_text(new + ("\n" if text.endswith("\n") else ""))
    print("block_eaves: %d blocks with eaves" % sum(1 for e in blocks if "eaves" in e))
    return 0


if __name__ == "__main__":
    sys.exit(main())
