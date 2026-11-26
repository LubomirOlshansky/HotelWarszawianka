# Godot add-ons (moved out of CLAUDE.md, 2026-10-31)

Pre-approved (the user, 2026-10-30): install without asking, one at a time, free only, and
name it in the PR. Prefer GDScript-only
add-ons under MIT or CC0; a native GDExtension needs iOS binaries (most don't ship them), so
check it on the phone before relying on it. Each goes in `game/addons/<name>/` with its
licence file kept, gets a CREDITS.md line (name, author, licence, URL, version), and must keep
the performance budgets. **Installed:** Debug Draw (HardPixel, v1.1.0, loop 3a; GDScript only,
loaded only with `--debug-roads`); Phantom Camera (Ramokz, v0.11.0.3, the camera loop; it runs
the fly-in and target-look tweens only, the follow camera is `follow_camera.gd`; its editor plugin
is off); beehave (bitbrain, v2.9.3, loop 3g-1; the police units' behaviour trees, ticked by
hand at 5 Hz; editor plugin off, no autoloads: `police/police_tree.gd` has a lean `_ready`; one
local line in `debug/debugger_messages.gd`, no messages without a debugger); Dialogue Manager
(Nathan Hoad, v4.1.0, loop 3g-1; the pull-over's flow, `dialogue/police.dialogue` compiled at
runtime by `police.gd`; editor plugin off, so no import plugin and no autoload). Autopilot (ramenvr/autopilot, release v1.0.0-c84203c of 2026-11-19 (Autopilot-Godot.zip, 1.6 MB, sha256 56ad876e, from github.com/ramenvr/autopilot), addons/autopilot, 2.0 MB, Apache-2.0; first added 2026-11-02, updated 2026-11-06 (v1.0.0-753232a, from 848084e) 2026-11-14 (to v1.0.0-1cb2383: the release's files with CRLF made LF, `agent_service/` left out, so the CLI comes from the same release; stray ui/history.gd.uid gone) and 2026-11-24 (to v1.0.0-c84203c, the latest release, the one the Mac hunts of 2026-11-23 ran on; same way, lib/trace.gd new; upstream main is 2 README commits past it); the free-play playtester, skill
`autopilot-playtest`; GDScript only; **off in git**: `tools/autopilot.sh on|off` turns the editor
plugin and its `AutopilotPlaytest` autoload on for a Mac run; excluded from every export and the
export scripts refuse to run while it is on). PostHog (PostHog, posthog-godot v0.1.4 of 2026, from github.com/PostHog/posthog-godot, addons/posthog, 136 KB, MIT, added 2026-11-15; the beta's anonymous play stats, docs/STATS.md; GDScript only; marked experimental upstream, real iOS/Android devices not yet verified by PostHog; editor plugin and autoload **off**: `play_stats.gd` makes the one instance, only in a release build with the setting on and the token file, so CI, benches and `--nosave` runs never start it). **Our own, not an add-on:**
`addons/nw_android_export/` (an editor plugin, on; it only marks Vulkan required in the Android
export's manifest; docs/archive/DEVELOPMENT-full.md "Android (Google Play)"). Candidates when a loop
needs them: Folder Import Rules, Lente photo mode, the In-app Review and Share plugins.

Taxi ride stories (2026-11-07): Dialogue Manager not used, because the story is three lines said while driving (bubbles at distance marks, the chatter budget) and one two-button side card that times out; the police balloon is a stopped-car scene. Beehave not used (no agent behaviour).
Zagłębie Kebabowe (2026-11-02): Dialogue Manager not used, because the craft shop's only choice is a two-button job card and the rest are single vendor lines (JSON bags); Beehave not used.

When to use Beehave and Dialogue Manager (decision rules and build patterns): skills `beehave-trees` and `dialogue-scenes` in `.claude/skills/`.
