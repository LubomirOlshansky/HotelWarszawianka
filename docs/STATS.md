# Play stats (the beta's anonymous analytics)

F, 2026-11-15: "a switch to turn analytics off in Settings, but no consent card for the beta; an
anonymous user ID so I see who comes back, who is online, how long they play; PostHog." Plan
doc: https://claude.ai/artifact/429FNJDfrpt6PRypbTaor3 (Ukrainian). F moved it into the beta
(2026-11-15 21:54 UTC) instead of the last step of the first-hour plan.

## How it works

- `game/scripts/play_stats.gd` is the one owner. `main.gd` builds it after the guide
  (`_build_play_stats`), hands it the systems once (`watch`) and calls `begin` (title gone),
  `pause` (background, close) and `resume`. It listens to signals; no feature calls it.
- The SDK is PostHog's official GDScript one (`game/addons/posthog`, v0.1.4, MIT, docs/ADDONS.md),
  EU Cloud (`https://eu.i.posthog.com`, Frankfurt), project "Around Warsaw".
  `person_profiles = NEVER`, no exception capture, no feature flags, the SDK's own
  `$app_opened`/`$app_backgrounded` lifecycle events on, `$locale` stripped in
  `before_send`; `$device_model` (the model code, e.g. `iPhone17,2`) is sent, plus the super property
  `device_name` (`iphone_16_pro_max`; an unknown code goes as its own slug). The project discards the client IP.
- **The anonymous ID** is the SDK's random `distinct_id`, kept in `user://posthog`; reinstalling
  makes a new one. Returning players, DAU and "online now" come from it.
- **Offline**: the SDK keeps up to 1000 events on disk and sends them when the network is back.

## When it sends

| Build / run | Sends |
| --- | --- |
| Release build (TestFlight, Play), setting on, a save, token file present | yes |
| Any debug build (editor, CI, `tools/verify.sh`, benches, Autopilot) | no |
| `--nosave` (every test run) | no |
| Settings → Dźwięk → "Anonimowa statystyka · Anonymous stats" off | no; the queue is dropped |
| `--stats=log` | prints `play_stats: <event> <json>`, sends nothing (check `stats`) |
| `--stats=send` | sends from a debug build if the token file is there (a device test) |
| `--stats=off` | no |

The token lives in `game/data/stats_key.json` (`{"api_key": "phc_…", "host":
"https://eu.i.posthog.com"}`), **gitignored**, written on the Mac only. `data/*.json` is in the
export's include filter, so builds made on the Mac carry it; a build without it sends nothing.
A PostHog project token is public by design (it can only send events), but it still stays out
of git (CLAUDE.md: no keys in tracked files).

## Events (the white list, `play_stats.gd` EVENTS)

| Event | Properties | Answers |
| --- | --- | --- |
| `session_start` | fresh_save, resumed (back from the background; a focus loss alone, such as Control Center, no longer ends a session from 2026-11-23), zl, load_ms (a launch: milliseconds from the engine's start to the start's sectors in; 0 after a resume), title_ms (engine start to the tap on "tap to drive"; 0 after a resume), quality (graphics level), crashed_before (the last session never ended in order) | sessions, new vs returning, load time by phone, graphics level, crash rate |
| `session_end` | minutes_played (this stretch only: since the launch or the last return from the background, so a launch's stretches add up; from 2026-11-23), km_driven, zl_earned, runs_done, heli_pct, how (`end` in order; `lost`: the session was killed or crashed in the foreground, sent at the next launch from a checkpoint file written every 15 s) | play time, what a session holds |
| (every event) | `$app_build` "0.1 (14, 839dfd2)": the version, the build number or Android version code and the commit, from data/build_stamp.json that tools/export_ios.sh and export_android.sh write ("0.1 (dev)" in a run from the editor) | which build a phone runs |
| `fps_sample` | avg_fps, low_fps, draw_calls, frame_cap (60 on an iPhone), minute, quality (the level drawn, a slug), scale (image pixels: 1 full, 2 half), flying | the phone's frame rate in the wild (twice: 2 and 10 minutes into play, so a phone that slows as it warms shows) |
| `guide_beat` | beat, how, t_play_s | the first-hour funnel (first10.gd beats) |
| `activity_start` / `activity_end` | activity, job, how (done/quit/timeout/ended; a street race says won/lost/quit from 2026-11-23), duration_s, t_play_s | which jobs and quests are played and finished |
| `first_job` | stage (start / end), activity, how, t_play_s (once per install each) | the drop between the guide's beats, the first job and its completion |
| `chase_end` | how, t_play_s | police chases |
| `discover` | kind (district/egg/napkin), id, t_play_s | exploration (napkin: a LISTA line ticked, napkin.gd) |
| `garage` | action (visit/paint/upgrade), id | the garage |
| `heli_landed` | t_play_s | the helicopter |
| `radio` | station | the radio |
| `setting` | key, value | which settings people change (choices only, no sliders) |
| `save_problem` | kind | damaged or failed saves |
| `stats_off` | | how many turn it off |

Every event also carries `platform` (`ios`, `android`, or `mac_ios_app` for the iPhone app on a Mac, from the model code `iPhone99,x`), `device_model`, `device_name` (`mac_ios_app` on a Mac), `os_version`, `test_device`, `lang`, `quality_tier`, `controls` (put on every event by `before_send`, so the SDK's own Installed/Opened events carry them too; before 2026-11-21 they and `$device_model` were missing on those and on builds before 18 Nov) and the
SDK's `$os`, `$os_version`, `$app_version`, `$session_id`. A string property must be a short slug
(`[a-z0-9_.-]`, at most 32 characters) or it is dropped, so no free text can leave.

A new event: a line in `EVENTS` and a listener in `play_stats.gd`, a row here and in
docs/privacy.md if it is a new kind of data, and the store answers checked.

## Privacy and the stores

docs/privacy.md (and the site's /privacy/), docs/store/app-store-connect.md section 4 (three data
types, not linked, not tracking, Analytics; the iOS preset's `privacy/collected_data/*`), and
docs/store/play-console.md "Data safety". Android has `permissions/internet=true` since this change.

## Reading the numbers

PostHog web app (EU), project "Around Warsaw" (id 351865): the dashboard "Around Warsaw: beta"
has DAU, sessions (new vs resumed), minutes per session, the first-hour funnel (fresh start → stand → choice
card → activity started → finished → guide done), D1/D7 retention, activities by kind and outcome, and
fps by quality tier. The project filters internal and test accounts by default, session replay is off,
IP discard is on, timezone Europe/Warsaw. The device model is sent since 2026-11-16 (`$device_model`, `device_name`): break fps and sessions down by `device_name` to count phones; `quality_tier` stays the main fps split.
The store forms for this are in docs/store/ (App Privacy: app-store-connect.md section 4; Data safety:
play-console.md section 3). The project can also be read with its free MCP server (`https://mcp.posthog.com/mcp`, only if F connects
it). Useful insights: DAU/WAU from `session_start`, retention (first `session_start` → any
`session_start` on day 1/7), average `session_end.minutes_played`, a funnel over `guide_beat`,
`activity_end` by `activity` and `how`, `fps_sample.avg_fps` by `quality_tier`.

## Test devices and Macs (2026-11-21)

DEV page → "Urządzenie testowe (statystyki) · Test device (stats)" sets `test_device=true` on every
event from that device. In PostHog use the project's test-account filter, or a filter on
`test_device = false` (events from builds before this change have no value: treat null as real).
A Mac running the iOS app reports `platform=mac_ios_app`; filter it out of the phone counts the same way.

## Gaps this closed

- `session_end` missing for killed sessions: a session file is written every 15 s and a leftover
  one at the next launch becomes `session_end how=lost` plus `crashed_before` on `session_start`.
  (Backgrounding already sent `session_end` and flushed; the queue is on disk, so it left at the next launch.)
- The queue is flushed every 15 s of play, not only on the SDK's 30 s timer and on pause.
- Gameplay events stopped after 20 Nov 13:41 because nobody played in that time: 21 Nov has one
  `session_start` at 10:19 and the app was backgrounded or killed within a minute, with no activity
  (no bug found in the sending path; the 20 Nov device and 18 Nov tester sessions arrive).
