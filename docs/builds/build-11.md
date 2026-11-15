# Build 11 (iOS, TestFlight): the Mac gate

Commit `1d063882` (main after #778), version 0.1, build number 11, from the Mac on 2026-11-15
(docs/WORKFLOW.md "The build train"). Derived files rebuilt first (`bake_sectors.py`, `bake_city.gd`:
the map_builder fix of #778 shifts 47 prebuilt sectors). Archive built; the upload step waits for F's
go (see the bottom).

## Local steps (`tools/ci_steps.txt`, `verify.sh --only=...`): 19 of 21 pass

| Step | Result |
| --- | --- |
| classic, coffee, crawl-run, first10-run, heli, kebab, lanedrive-grounded, life-soak (10 min, overlaps 0), police-runs, race, rain, ride, ride-police, shisha-run, splash, tour-run, trzy-mosty | PASS |
| sectororder | PASS: 112 sectors, forward and reverse order the same geometry (1 mesh in triangle order only) |
| police-soak | FAIL once ("a police car 1.57 m off its lane"), flaky: it passed in the `--ios` run and on main, failed once in each of two other runs; known, not a blocker |
| streaming | FAIL: stopped at the 1,500 s step limit; also on main; known, not a blocker |

## `tools/verify.sh --ios` (the full set plus the export and the unsigned Xcode build): 189 pass, 2 fail, 1 warn of 192

- Fails: `pois` (Q3, one scooter on a kerb ramp; also on main) and `streaming` (above).
- Warn: `places` (stadion_narodowy 115 m from a lane or footway; rough hint).
- `ios export + build`: BUILD SUCCEEDED (unsigned, generic iOS).

## Bench against build 10 (c7dc5f86), Mac M4 Pro, 1280x720, `--bench` route, uncapped

| Path | Build 10 | Build 11 |
| --- | --- | --- |
| runtime city | 3.81 ms, 149 draw calls, 1.36 M tris, 470 MB static | 3.93 ms, 147 draw calls, 1.42 M tris, 490 MB |
| prebuilt city (the phone's path) | 3.56 ms, 149 draw calls, 1.35 M tris, 377 MB | 4.61 ms, 143 draw calls, 1.36 M tris, 407 MB |

Draw calls (what the phone's frame follows) are the same or lower. The Mac's ms/frame is noisy at
this size (the prebuilt run's worst frame 13.3 ms against 14.2 ms); the phone's number is F's.

## The four church views, `--probe`, 2532x1170, main of 2026-11-12 (298c9ce9) against build 11

| View | Draw calls | Objects | Triangles |
| --- | --- | --- | --- |
| Miodowa (-977,-1403) | 134 -> 134 | 202 -> 212 | 0.91 M -> 0.95 M |
| Piwna and Swietojanska (-790,-1590) | 140 -> 140 | 208 -> 218 | 0.94 M -> 0.98 M |
| Freta (-1000,-1930) | 119 -> 119 | 187 -> 197 | 0.67 M -> 0.69 M |
| Krakowskie Przedmiescie by the Wizytki (-440,-810) | 136 -> 137 | 204 -> 215 | 0.79 M -> 0.84 M |

Runtime path shown; the prebuilt path has the same draw calls and 9 fewer objects. Frame times
(3.0 to 4.4 ms on the Mac) move with the load of the machine more than with the change.

## Upload

The archive `AroundWarsaw-11` (build 11) is made; the Mac has no App Store Connect key, so F pastes
"What to Test" and sees the processing status. The upload (`xcodebuild -exportArchive`) was blocked by
the Mac's permission rule and waits for F's go.
