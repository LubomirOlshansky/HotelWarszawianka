# The building modelling pipeline: review and what to optimise (2026-11-13)

F asked for a review of how buildings and landmarks get made, where the pipeline is weak, and how
to optimise it. This is a review only: no game code changed. Numbers were measured on main at
`d6a9645` in a cloud container (Godot 4.7.2, lavapipe under xvfb), unless a line says otherwise.

## 1. The pipeline today, in one screen

| Step | How it works now | Owner |
| --- | --- | --- |
| Photos | `refs/<slug>/` on the Mac (gitignored): Commons and the GUGiK orthophoto from the Mac only, Mapillary/Panoramax from anywhere (`tools/street_photos.py`); F's own photos in chat and in Mac folders; a text report in `docs/landmarks/photo-reports/` for cloud threads | Mac session, F |
| Spec | `docs/landmarks/specs/<slug>.md`, eight sections, checked by `tools/check_spec.py` | lane session (Opus) |
| Build, way A | a `_build_<site>` function in `game/scripts/landmarks.gd`, triangles poured into the city's one building surface (material codes `M_*`, skins `S_*` in `building.gdshader`): no draw call of its own, on both city paths, in the sector scenes | `object-modeler` (Sonnet) |
| Build, way B | a place script of its own (`patelnia.gd`, `tamka.gd`, `ratusz_hub.gd` ...): one mesh in the actors' material, built at runtime, wired by hand in `main.gd` | the thread |
| Build, way C | Blender (`tools/blender/pkin.py`) exports a glb, `_palace_glb` pours it into the city surface (trial, the Palace only, behind `--palace=blender`) | Mac only |
| Automatic checks | `check_mesh_quality` (triangle budget, z-fighting, floating parts, bad normals), `check_sites`, `check_landmarks`, `check_shader_budget`, `check_spec` | CI tier `landmarks`, 20-25 min |
| Looks | `tools/shots.sh`, `--solo=<site> --solo-look=lit|flat|sil`, `tools/shot_sheet.py` for before/after | the thread |
| Acceptance | `art-director` scores against the photos, then F's look check, parked in `docs/QUESTIONS.md` | Opus, then F |
| Bookkeeping | spec, `LANDMARKS.md`, `CITY_INVENTORY.md`, a log per landmark, a change note | the thread |

What is strong and should stay: detail costs triangles and not draw calls; the mesh check is a
ratchet that really holds (251 sites, 405,912 triangles, **one** known defect left in the whole
city); specs are machine-checked; one `gate` check; change notes ended the docs conflicts.

## 2. What was measured

| Thing | Number |
| --- | --- |
| `landmarks.gd` | 1.75 MB, 35,951 lines, 972 functions, 201 `_build_*`, 115 `_find_*`, 2,631 constants, 1,880 hex colours |
| One site built alone | 1 to 80 ms (Arkadia, the largest at 14,796 triangles, 80 ms) |
| `check_mesh_quality`, all 251 sites | 77 s |
| A `--solo` shot of one site | 40 s, of which the site is a few ms; 18.6 s is the map-edge roadworks and 6.8 s the sector proxies, neither in the picture |
| A shot in the real city, runtime path | 4 min 20 s (the city builds in 227 s), without the map pack's LoD2 and terrain |
| Building shader, Adreno budget | **502 of 505** (`check_shader_budget`); `graphics.md` and TD-9 still say 498 of about 508 |
| Skin styles | 16 of 16 slots taken; `S_DIAMOND` has a shader branch and no user in any script |
| Private window and pane helpers in `landmarks.gd` | 21 (`_euro_window`, `_fk_window`, `_sm_window`, `_hw_panes`, `_dp_panes` ...), plus 8 balcony, 6 pediment, 6 ledge, 4 column helpers |
| Specs / logs / photo reports | 141 specs, 13 logs (`docs/landmarks/<slug>.md`), 56 photo reports; scores are written down in 3 logs |
| Open look and photo checks | "photo check" or "look check" appears 77 times in `QUESTIONS.md`, 105 in `BACKLOG.md`, 44 in `CITY_INVENTORY.md` |
| Place scripts (way B) | 18 scripts, 6,684 lines; none of the six looked at sets a visibility range; none is in the mesh check or has a triangle budget |
| `docs/models/library.md` | says 125 landmarks; the generator now counts 185. It also stores `landmarks.gd:<line>` for every model, which moves with every edit |
| Blender Palace | 23,084 triangles against the code model's 3.6k in the PR's count; 3.1 MB of glb in git; the plan (`P_WINGS`, `P_BLOCKS`) is copied into `pkin.py` by hand |

## 3. Weak places

**W1. Looking at a model is the slow part, not building it.** A site builds in milliseconds, but
every look costs 40 s (solo) to 5 min (in the city), one angle per run. The skill asks for a
matched shot per photo, a flat and a silhouette shot per main angle, before/after and the
prebuilt path: 10 to 16 runs for one L3 landmark. Threads therefore take two or three shots and
miss the sides nobody looked at (the default yaw never shows west walls). The solo shot is also
not clean: the car stands inside the model, a kebab stand floats beside it and a grid of lines
covers the roof.

**W2. F is the last gate for everything, one question at a time.** Around 80 look checks wait in
text form. Each needs F to find the thread, the shot and the photo. The backlog of unchecked models
grows faster than it clears, so "done" models stay unverified (the churches review found 5 own
models and 22 kit churches never compared with a photo). The art-director scores exist on paper;
they are recorded for 3 landmarks.

**W3. Photos live in places the builder can't open.** `refs/` is on the Mac; F's photos are spread
over at least six folders (`warsaw-needed-photos`, `top-50`, `pkin-surroundings`, chat uploads,
`/mnt/project-files/*-photos`); the cloud can't reach Commons. A cloud thread builds from a text
report or asks for a Remote Control run, and the spec's values become second-hand. There is no
single index of "which building has which photos where".

**W4. Every landmark invents its own facade parts.** 21 window helpers, each with its own
proportions, reveal depth and night-light rule; colours as 1,880 one-off hex values. This is the
main reason models look inconsistent beside each other, and the main reason a landmark takes
300-400 lines (Dom Partii: +353 lines, five helpers of its own).

**W5. One 1.75 MB file.** No session can read it; every landmark PR edits the same four spots (the
`match` in `build`, `tower_colour`'s chain, `SKINS`, `_find_sites`), so parallel threads collide
and re-run a 20-25 min tier after each merge of main. It also costs 1.2 s of script compile
(TD-10, open).

**W6. The shader has 3 units left and no skin slot.** Any new facade look has to be geometry
(Dom Partii's windows are about 1,700 quads), which is fine for draw calls but pushes triangles and
the shadow pass up. Meanwhile a dead branch (`S_DIAMOND`) and several one-building branches
(`S_KEYS`, `S_ESTATE`, `S_EASTWALL`, `S_GOLD`, the stadium's `weave`) hold budget.

**W7. Way B grows the draw-call count quietly.** Each place script is one more draw call whenever
it is in view, at any distance, with no budget, no mesh check and a hand-written hook in
`main.gd`. Three or four are fine; the Powiśle "life" plan (about 25 bars, gardens) and the
landmark threads now starting would add dozens.

**W8. Blender is a second pipeline with no guard rails yet.** Only the Mac can export; CI can't
tell whether the committed glb matches the script; the plan is duplicated by hand, so the code
model and the Blender model drift; the glb's 23k triangles are outside the mesh check's budget
(the Palace's budget is the code model's); `_palace_glb` is Palace-only; LOD 1 exists and nothing
uses it; binaries grow the repo.

**W9. Rules that disagree with each other.** CLAUDE.md and the model-from-photos skill tell a
thread to edit BACKLOG, ROADMAP, CHANGELOG, LANDMARKS.md and a log; `docs/changes/README.md`
forbids the first three. The skill puts triangle budgets in `check_sites.gd`; they live in
`check_mesh_quality.gd` (305 entries, a conflict hot spot, 39 commits) and again in each spec.
Status is hand-ticked in four files, so they disagree. The skill's own evals (section 7) were
never run, so nobody knows whether the spec step earns its Opus time.

## 4. What to do, ranked by payoff

Payoff = time or quality won for every future landmark, against the work to build it.

| # | Change | Fixes | Work | Payoff |
| --- | --- | --- | --- | --- |
| 1 | **A site turntable.** One command, one run: build only the site (the mesh check already does this in ms), skip everything else, render 8 yaws at two pitches plus straight down, lit, flat and silhouette, and write one contact sheet. With the photos beside it when `refs/<slug>/` exists. The free-camera thread (`--cam-pos`, `--cam-look`) should take a list of cameras in one run so this tool is a thin wrapper | W1 | small (1 PR) | a full review set in under a minute instead of 10-60; every side gets looked at |
| 2 | **One review board for F.** A page with a row per waiting landmark: photo, turntable sheet, the art-director's scores, and OK / redo / note buttons. Threads post to it instead of parking a text question. One sitting clears twenty checks | W2 | small-medium | removes the real bottleneck; "done" starts to mean checked |
| 3 | **One photo store with an index.** Mirror `refs/` into the project's shared folder (`/mnt/project-files/refs/<slug>/`, never in the repo, never shipped), fold F's six folders into it, and keep one `INDEX` by inventory rank (photos yes/no, ortho yes/no). One weekly Mac job fills gaps by rank instead of a Remote Control run per thread. Built (2026-11-13): tools/refs_store.py (index, gaps, show, where, pull, push, `ALIASES.tsv`), tools/refs_slugs.tsv, verify step `refs-store`; the photos themselves still have to be copied in | W3 | small | cloud builders see the photos; no thread waits for the Mac |
| 4 | **A facade kit and a palette.** Shared, tested parts in one helper file: window grid, ledge ring, pilaster grid, cornice profile, colonnade, portico with pediment, balcony, attic, roof lantern; about 25 named materials (white stone, sandstone, red brick, patina copper ...). Specs name kit parts in the parts table. A ratchet stops new private `_xx_window` helpers | W4 | medium | a landmark becomes 50-100 lines; Sonnet builds it right the first time; the city reads as one hand |
| 5 | **Split `landmarks.gd` by site, with a parity proof.** One file per site (or per area) with `find` and `build`, a registry table instead of the `match` and the `if key ==` chains, the kit in its own file. Proof that nothing changed: add a per-site vertex hash to `check_mesh_quality` first, record all 251, move the code, compare. Do it in one quiet window with no landmark PR open | W5 | medium, mechanical | no more collisions between landmark threads; a session can read a whole landmark |
| 6 | **Free the shader instead of fighting it.** Delete the `S_DIAMOND` branch now (a free slot and budget). Then measure each one-building branch with `check_shader_budget` and move those looks to geometry or vertex colour. Only if that is not enough, TD-9's own landmark material (which costs a draw call per sector in view, so it needs a phone bench) | W6 | small now, medium later | room for the next looks without the Adreno risk |
| 7 | **DONE 2026-11-13 (`place.gd`, `places.gd`, `Places.TABLE`, `check_place_scripts.gd`; merged per 512 m sector; no distance range, see decisions.md).** **One owner for place dressing.** A small base for way-B scripts: registered in a table (no `main.gd` edit), a visibility range by default, a triangle budget and the mesh check, and one merged mesh per sector when several places share it. Before the Powiśle bars start | W7 | medium | draw calls stay flat as the city fills up |
| 8 | **Rules for Blender before a second model.** Blender only for the Tier S heroes (about ten). The plan read from one shared JSON, not copied. Blender installed in the cloud (it runs headless on Linux, a pre-approved free download) so any thread and CI can re-export and compare. A general `_glb_site`, the glb inside the mesh check with its own budget, and a phone bench of the shadow pass before it becomes a default | W8 | medium | Blender stays an asset, not a second source of drift |
| 9 | **One source for each fact.** Budget only in the spec (the check reads it). Status generated from specs, code and the review board into one table. `library.md` without line numbers, or not committed. CLAUDE.md, the skill and `graphics.md` brought in line with change notes and the real numbers | W9 | small | fewer conflict files, no stale docs |
| 10 | **Run the skill's eval once.** Three landmarks, with and without the spec step, same builder, scored blind. It decides whether Opus spec time is worth it or a kit-based brief is enough | W9 | small | may halve the cost per landmark |

**Suggested order:** 1, 3, 6 (the delete) and 9 are small and independent and can go now. 2 follows
1. 4 before 5, so the split moves kit calls and not 21 private helpers. 7 before the Powiśle life
lane. 8 only if F picks Blender for more heroes.

## 5. What this review did not measure

- Phone cost. Triangles and the shadow pass on the tile GPU, and the load time of way-B scripts at
  boot, need a device bench.
- The Mac side: how long a photo gather run takes, and what is really in F's photo folders.
- How many fix rounds a typical landmark needed; the logs that would say so are mostly missing.
