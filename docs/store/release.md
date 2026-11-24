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

- **iOS:** export, archive and upload with `xcodebuild` (automatic signing, team S6PVT5UP7G); the
  build lands in internal TestFlight after Apple's processing.
- **Android:** `tools/export_android.sh` builds the signed AAB (also copied to `~/Downloads`), and
  with the Play key `fastlane supply` uploads it to open testing (`beta`) as a draft.
- **`--open-beta --notes=DIR`:** no manual step. The Play release is rolled out to open testing;
  the iOS build gets its What to Test, joins "Beta test external" and goes to Apple's beta review.
  Missing keys or notes stop it before the build. Production and the App Store are never touched.
- **Numbers:** the last ones are in `~/.config/aroundwarsaw/release-numbers`; with the keys the
  store's latest number is checked too and the higher wins. `--ios-build=N`, `--android-code=N`.

## Keys (none of them in git)

All in `~/.config/aroundwarsaw/`, each key file `chmod 600`; `tools/release.sh --check-keys` tests
them. fastlane: `brew install fastlane`.

| What | How, once |
| --- | --- |
| `AuthKey_<ID>.p8` and `release.env` (`ASC_KEY_ID`, `ASC_ISSUER_ID`) | App Store Connect, Users and Access, Integrations, Team Keys, +, role App Manager. The `.p8` downloads once only |
| `play.json` | Google Cloud: a project, enable the Google Play Android Developer API, a service account with no Cloud roles, Keys, JSON. Play Console, Users and permissions: invite its email, this app only, "Release apps to testing tracks" (and "View app information") |

## MCP?

There is no official App Store Connect or Google Play MCP server, and the community ones wrap the
same two APIs with the same keys. A script is easier to audit and runs without a Claude session,
so the pipeline stays a script; a session runs it like any other tool.
