# Beta releases in one command

`tools/release.sh` takes a git ref (default `origin/main`) to TestFlight and Google Play open
testing on the Mac. It builds in `/private/tmp/aw-release` (a `git archive` copy plus the
untracked bits from the checkout: `game/.godot`, `game/icons`, `game/android`,
`game/data/stats_key.json`, `lod2.*`, `terrain.json`), so the checkout's own uncommitted work is
never touched. It bakes the city once for both platforms.

```zsh
tools/release.sh                  # both stores, numbers = last + 1
tools/release.sh --ios            # TestFlight only
tools/release.sh --android        # Play only
tools/release.sh --no-upload      # build and sign only
tools/release.sh --keep --skip-bake --ios   # retry an upload without rebuilding
```

What it does:

- **iOS:** export, archive and upload with `xcodebuild` (automatic signing, team S6PVT5UP7G). The
  build lands in the internal TestFlight group after Apple's processing. The script never adds
  it to the external group: that sends it to Apple's beta review, and only F decides it.
- **Android:** `tools/export_android.sh` builds the signed AAB and copies it to `~/Downloads`.
  With a Play service account key it uploads to the open testing track (`beta`) with
  `fastlane supply`, as a **draft** release; `--rollout` publishes it at once. Production is never
  touched.
- **Numbers:** the last uploaded build and version code are kept in
  `~/.config/aroundwarsaw/release-numbers` (outside git). With the store keys below, the store's
  own latest number is checked too and the higher one wins. `--ios-build=N` and
  `--android-code=N` force a number. main's `export_presets.cfg` never carries the numbers or
  the icon lines: the script writes them into the build folder's copy only.

## Keys (none of them in git)

| What | Needed for | How |
| --- | --- | --- |
| Xcode signed in to the Apple account | iOS upload | already on the Mac (Xcode → Settings → Accounts) |
| App Store Connect API key (optional) | iOS without an Xcode sign-in, the build-number lookup | App Store Connect → Users and Access → Integrations → Team Keys → +, role App Manager. Download the `.p8` once, keep it in `~/.appstoreconnect/`, and export `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_PATH` |
| Play service account JSON key | Android upload | Google Cloud console: a project → IAM → Service accounts → create one → Keys → Add key → JSON. Then Play Console → Users and permissions → Invite new users → the service account's email, app Around Warsaw, permission "Release apps to testing tracks". Keep the JSON in `~/.android-keys/` and export `PLAY_JSON_KEY` |
| fastlane | Android upload, lookups | `brew install fastlane` |

## MCP?

There is no official App Store Connect or Google Play MCP server, and the community ones wrap the
same two APIs with the same keys. A script is easier to audit and runs without a Claude session,
so the pipeline stays a script; a session runs it like any other tool.
