# Decisions: what was chosen, and what was chosen against

One row per architecture decision, so nobody argues it again without new facts. Look here before
you propose a new pattern. To change a decision, bring the new fact to F, then edit the row in the
same PR as the change (keep the old row under "Replaced" with one line on why).

## In force

| Decision | Why | Since |
| --- | --- | --- |
| **One composition root, no autoloads of the game's own.** `main.gd` creates and wires every system. | Every dependency is visible in one place, and a check script can build a system with fakes. | the start |
| **References are passed in** as properties and Callables; no script finds another by node path. | A system can be tested alone and moved without breaking a path. | the start |
| **Rules apart from nodes.** Numbers and decisions live in pure scripts with a `check_*.gd` each. | Rules are tested in seconds, without the map. | the start |
| **Cars are cursors on the lane graph; people are instances in one MultiMesh.** No node per car or person. | The phone's frame grows with draw calls, not triangles. | the start |
| **Both city paths give the same city** (runtime build and prebuilt sectors). | The Mac tests the first, the phone ships the second. | the start |
| **The save is one versioned ConfigFile** owned by `wallet.gd`; an older build never overwrites a newer save. | One place to migrate; a tester can move between builds. | save version 2 |
| **A save that can't be read is never written over or deleted.** It is moved aside and the last launch's copy is loaded; a missing file is a fresh start. | Progress is the one thing a tester can't get back. Deleting the file must still reset the game. | TD-8, 2026-11-12 |
| **Testers' builds are not changed to catch errors.** They stay on the release engine and run none of the error trap: no logger, no report button, no note and no log file. Script mistakes are found in debug runs (the checks, Autopilot on the Mac, device runs on F's phone), where the error trap keeps them with their lines; errors are kept for a report, never shown as they come. | F, 2026-11-12: speed for testers comes first, and a tester would not send a report. The release engine hides a script's mistakes anyway (TD-21). | TD-14, 2026-11-12 |
| **A player's launch and a test run start differently.** With no flags (every release build) the boot scene shows the title and loads the game behind it; with flags the game's scene loads at once. `--boot` and the verify step `boot-run` cover the player's way. | A frame going by before the game would move every run's `--quit-after` and `--shots` frame counts, and a test run has no use for the title. | TD-15 |
| **One language on screen; every text is written as a Polish and English pair.** | F, 2026-11-02; English by default since 2026-11-08. | 2026-11-02 |
| **One decision for HUD text** (`messages.gd`) and one for bubbles (`chatter.gd`). | Messages from several systems used to overlap on screen. | PR #652 |
| **Add-ons only where they earn it**: Beehave for the police and authored scenes, Dialogue Manager for branching scenes. | Everything else is cheaper and clearer as plain code. | docs/ADDONS.md |
| **No rubber band in races.** Difficulty comes from each rival's skill. | A race the player can't lose or can't win by driving is not a race. | docs/design/race-ai.md |
| **The police never fine.** Warnings and jokes; every chase ends by itself. | The tone of the game. | docs/design/police.md |
| **Facade elements come from one kit, and the kit grows instead of the landmarks.** Windows, balconies, ledges, cornices, pilasters, columns, pediments, porticos and lanterns are `kit_*` parts of `facade_kit.gd` with fixed proportions; wall, trim, roof and glass colours are `PAL_*` names. A landmark that needs what the kit lacks adds the part or the style to the kit in its own PR, with the part in the sampler and in docs/design/facade-kit.md. | 21 private window helpers and 1,852 one-off colours made neighbours look like different games, and a landmark cost 300 to 400 lines. With fixed proportions the second landmark gets the same look for nothing. | F, 2026-11-13; PR #726 |
| **A refactor of the landmark code is proved, not looked at.** `site_dump.gd` writes every vertex of every site and `site_parity.py` compares before and after: a move of code must give every site bit for bit; a private helper replaced by a kit part must give each triangle a twin of the same colour within 6 cm. | 1,213 sites cannot be checked by shots, and a shot misses the sides nobody looked at. | PR #726 |
| **Every script has one row** in systems.md or city-ai.md, and a workaround is marked `# WORKAROUND(arch)`. | The map of the code can't go stale. | PR #654 |
| **Places: merged per sector, no distance range.** Place scripts hand their static dressing to `places.gd`, which merges it into one mesh per 512 m sector. The review (item 7) asked for a visibility range too; there is none. | The camera is orthographic and sits 500 m back at every play zoom, so a range in metres from the camera cannot tell near from far on screen, and the frustum already culls what is off screen. A 512 m sector mesh puts more triangles in view than the old per-place meshes (at the Patelnia 40,720 before, 58,364 at 512 m, 45,088 at 256 m) and fewer meshes (7 before, 5 at 512 m, 6 at 256 m); `Places.CELL` is the knob. | 2026-11-13 |
| **One script per kind of activity, one data file per instance.** The two tours are `tour.gd` with `kino_tour.json` and `dekalog_tour.json`. | They were near copies of 479 and 541 lines. A new tour needs no code, and `check_activity` reads and plays every tour's data. | 2026-11-12 (TD-1) |
| **The card's owner is named after the card is shown** (`hud.own_card(self)`), not by a new parameter of `show_card`. | `show_card`, `show_side_card` and `show_call` and their callers keep their signatures, and a card nobody owns behaves as before, so the activities move to the kit one PR at a time. | 2026-11-12 (TD-16) |
| **An activity that moves to the kit is proved against its old script before the old one is deleted**: both driven with the same inputs, frame by frame, comparing what each puts on the HUD, says and pays. | The words and the timings are copied by hand, and a check written for the new script alone would not see a changed word. | 2026-11-12 (TD-1) |
| **In the kit, "busy" has one meaning: from the offer card to the close of the result card.** A ringing phone is not busy. While a kit activity is busy no side job starts (Podwózka, the kebab and trend jobs stand down, as during a tour). | The scripts each had their own: the bar crawl was not busy while its offer or its result card was up, and a kebab delivery could be started in the middle of a crawl. An activity that moves takes the kit's meaning, and its PR names what changed for the player. One exception, set by the script (`offer_busy` off): a job whose request is a card beside the road as the player drives past (the trend job's ACCEPT / SKIP) is busy only from the moment it is taken, as it was before the kit: everything that asks "is a job on?" gets the answer it got then, and a card the player has not answered holds nothing back (Podwózka alone waits for the card too, through `jobs.side_busy()`, as before). | 2026-11-12 (TD-1, the bar crawl); the exception 2026-11-13 (the trend job) |

## Decided against (second review, 2026-11-12; F can overturn any of these)

| Idea | Why not |
| --- | --- |
| A global event bus or a signal autoload | It hides who talks to whom. Passing references in can be traced and tested. |
| An entity-component system, or a node per car and person | The lane-graph cursor and the shared MultiMesh are already the cheap pattern for a phone. |
| A state machine add-on for activities | The base class (`activity.gd`, TD-1) is under 400 lines with its cards and target; an add-on brings a dependency and an editor workflow agents can't use. |
| A private window, balcony, ledge, cornice, pediment or column helper inside a landmark (`_xx_window`) | It is how the city got 21 kinds of window. `tools/check_facade_kit.py` fails a new one; the 37 that remain are listed there and only leave. |
| Proportions as arguments of a kit part (sill depth, rail height, reveal) | Every landmark would pass its own numbers and the kit would unify nothing. A different proportion is a new named style, decided once, with a look. |
| A new facade look in the building shader | The shader is at 502 of 505 Adreno instructions and all 16 skin slots are taken. Kit parts are geometry in the materials that exist. Look again after the shader is freed (pipeline review item 6). |
| Moving every landmark to the palette's colours in one PR | Each move changes a look a little; 185 unreviewed look changes at once is how unverified models pile up. A landmark takes palette names when it is next reworked, with its look check. |
| A full localisation system (CSV, gettext) | Two languages, and the pair pattern works: every toast has its English. Look again if a third language is asked for. |
| Splitting `hud.gd` before cards have an owner (TD-16) | It would move the tangle into five files. After TD-16 it splits along owners. |
| The engine's own file logging (`debug/file_logging`) as the crash trail | A release build flushes it only on an error (`core/io/logger.cpp`), so the lines printed before a crash are still in memory and are lost; and nothing in it says a session ended in order. The trap's session file is flushed line by line and stays under 2,000 lines. |
| An error overlay or a toast per error on test builds | The first plan had the errors on the BENCH card. A button in Settings (debug builds) needs no bench run. |
| Betas on the debug engine, or tracked call stacks in release | F, 2026-11-12: testers' builds are not slowed (TD-21 has the numbers). |
| The title's art as the engine's boot splash image | The boot scene (TD-15) shows the real title, with its language buttons and a moving bar, as soon as the engine draws; a still copy would have to be kept in step by hand. Look again if a phone run shows the engine's own start is still long. |
| A new save format (JSON, SQLite) | ConfigFile is fine. The risk is in how the file is written (TD-8). |
| A "planned" owner with no place in tech-debt's order | A rule agents can't follow yet is noise. Name what is built or what is next. |

## Replaced

None yet.
