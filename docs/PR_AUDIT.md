# PR and branch audit, 2026-11-07 (about 14:00 Warsaw)

Repo: LubomirOlshansky/HotelWarszawianka (renamed from AroundWarsaw). Measured against `main` at 96402752 with `git merge-tree` on each PR head, plus GitHub check runs. Main moves every few minutes, so "behind" numbers age fast.

## Short answer

41 open PRs and 384 `claude/*` branches. **No work is truly lost**: every open PR holds code that is not on main, and no unmerged branch without a PR holds unique work. But 28 of the 41 PRs conflict with main, and 13 of those have been sitting since 11-06 or earlier with green CI and nobody rebasing them. That is the same situation as the radio PR #454. They are the risk.

## Most at risk (stale, conflicting, owner thread gone)

| PR | What it holds | State | Behind main | Conflicts in | Recommendation |
| --- | --- | --- | --- | --- | --- |
| #496 | Closed-beta fixes PT-19, PT-25..28 and build 4 "What to Test" | CI green, conflicts | 16 | docs | Rebase and merge first. Beta testers wait on it. |
| #456 | 3D LED screen at Złote Tarasy, Skylight rebuild (10 commits, 6 code files) | CI green, conflicts, open since 11-05 | 33 | verify.sh | Rebase, merge. |
| #482 | Mrożulo's "Dżemini" call, TYGRAM, MLASK sticker, queue | CI green, conflicts | 33 | docs | Rebase, merge. |
| #479 | Rondo Daszyńskiego towers RD-1..4 | CI green, conflicts | 33 | brand_denylist.json | Check against the RD-1..6 detail pass in memory, then rebase or close as superseded. |
| #486 | Station furniture and waiting people | **No CI ever ran**, conflicts | 32 | docs, map_builder | Rebase to trigger CI, then merge. |
| #467 | Palace streets bookkeeping (docs only, 1 commit) | CI green, conflicts | 54 | docs | Likely superseded by newer docs. Recommend closing after a check. Needs F's yes. |
| #477 | Prosta 32, Prosta 28, Łucka City from F's photos | CI green, conflicts | 16 | check_mesh_quality.gd | Rebase, merge. |
| #478 | Warsaw Spire, B and C, LED ticker (13 files) | CI green, conflicts | 27 | verify.sh | Rebase, merge. |
| #493 | National Museum, St John's, Barbican, St Anne's, Holy Cross | CI green, conflicts | 16 | docs | Rebase, merge. |
| #489 | Batch 4: Ilmet, Rondo ONZ, Teatr Wielki | CI green, conflicts | 19 | docs | Rebase, merge. |
| #487 | New and old trams in traffic | CI green, conflicts | 19 | verify.yml, verify.sh | Rebase, merge. Overlaps #518 (tram tracks), check order. |
| #484 | SOWA CLUB and CITY 25 neon pavilion | CI green, conflicts | 16 | dialogue.json | Rebase, merge. |
| #473 | Zachodnia offices, BLUZOFT sign, jokes | CI green, conflicts | 9 | docs | Rebase, merge. |

## Clean and green but not merged (just need a merge slot)

- **#371** Monuments pass part 2 (seven monuments). Open since 11-02, 27 behind, clean, all 4 checks green, owner thread closed. Merge it today.
- **#491** Autopilot add-on update (vendored release, 64 files), clean, green.
- **#488** Park the Constitutional Tribunal (docs only), clean, green.
- **#490** Batch 3 photo pass. It also carries the Staszic, All Saints, Zygmunt and Świętokrzyski photo reports, which are on no other branch.
- **#502, #503, #504, #506, #507, #512, #513**: clean, checks still running or green, merge as they finish.

## Active, conflict is fresh (thread should fix itself)

#499 night racing, #500 padel, #505 guide fix, #509 credits, #510 camera angle, #511 bus stops, #481 coffee run, #498 LIM podium (CI was failing on the last run, re-running now). These are 3 to 9 commits behind, created today or yesterday. Watch them: if still conflicting in a few hours, treat them as stale.

## In flight, left alone

#508 (holds the slot), then #485, #515, #517. #516, #518, #519, #520 self-merge on green. #454 radio is being merged by its own thread. Note #517 conflicts in tools/verify.sh and #485 has 33 commits ahead of main.

## Where conflicts come from

Hotspot files touched by many open PRs: `game/scripts/main.gd` (16 PRs), `game/scripts/landmarks.gd` (14), `tools/verify.sh` (13), `game/tools/check_mesh_quality.gd` (11), `map_builder.gd` (8), `verify.yml` (7). Every PR that adds a check line to verify.sh conflicts with the next one. Merging them one at a time with a rebase between each is the only way through. Idea: a merge queue on GitHub, or one "rebase the stale ones" thread run PR by PR.

## Branches without an open PR

384 `claude/*` remote branches:
- 174 are fully merged into main.
- 156 more are squash-merged leftovers: their tip equals the head of a merged PR. Safe to delete (needs F's yes).
- About 41 belong to the open PRs above.
- The rest I checked by hand:
  - `claude/batch3-photo-reports`, `daszynskiego-photo-reports`, `project-thread-conzxt`: docs-only photo reports. Batch 3 is inside #490, the other two are on main.
  - `claude/steer-sensitivity`: the sensitivity slider and Cruise/Sport profiles are on main (settings_panel.gd, check_handling.gd).
  - `claude/landmarks-claim`, `roadworks-knock`, `project-thread-cf0hz6` (#86), `ldyr9u` (#53), `02ql05` (#182): old 10-30 to 11-01 branches that are all merge commits of PRs already merged.
  - Closed #303 (K6 Norblin candelabra, Browary trees): landed on main as a9dabfb7.
  - Closed #450 (radio): replaced by #454 on the same branch.
  - **Closed #455 (`project-thread-2tf2dc`): "Bump release to 1.0.2 (iOS build 1, Android code 9)", one commit, never merged.** Main still says iOS version 1, short 0.1, Android code 2. Memory says TestFlight build 3 and Android code 8 shipped from elsewhere. F's call: bump on main or keep build numbers off the repo.

## Suggested actions (all need F's yes, nothing was done)

1. Merge #371 now.
2. One thread rebases and merges the 13 stale conflicting PRs one at a time, #496 first, then #456, #482, #477, #478, #493, #489, #487, #484, #473, #486. Check #479 and #467 for supersession before touching them.
3. Delete the 330 merged branches (174 + 156) in one pass.
4. Decide on #455.
5. A small rule: any PR open more than 12 hours with conflicts gets re-pinged by the coordinator.

Snapshot at 14:00. Afterwards F approved the merges; the orphan PRs went to main (see ROADMAP and BACKLOG, 2026-11-07).
