# Beta releases in one command

`tools/release.sh` takes a git ref (default `origin/main`) to TestFlight and Google Play open
testing on the Mac. It builds in `/private/tmp/aw-release` (a `git archive` copy plus the
untracked bits from the checkout: `game/.godot`, `game/icons`, `game/android`,
`game/data/stats_key.json`, `lod2.*`, `terrain.json`), so the checkout's own uncommitted work is
never touched. It bakes the city once for both platforms.

```zsh
tools/release.sh --notes=DIR --open-beta   # gate, build, both stores, out to the outside testers
tools/release.sh --notes=DIR               # the same, stops at internal testing (the candidate)
tools/release.sh --promote --phone-ok="F, iPhone 16 Pro Max"   # the candidate's own files go out
tools/release.sh --gate-only               # only: may this commit ship?
tools/release.sh --no-gate                 # internal only, can never be promoted
```

`DIR` holds `en-GB.txt` and `pl-PL.txt`, up to 500 characters each.

- **The gate** refuses to build unless CI's `verify` is green on that exact main commit and the
  `local` steps of `tools/ci_steps.txt` pass on the Mac, a warning counting as red. The fast gate
  leaves the longest steps to the night; `--thorough` runs all. Exceptions: only lines of
  `tools/release_known_red.txt`, each with a reason and F's yes. Logs: `~/.config/aroundwarsaw/gate/`.
- **iOS** goes out with `xcodebuild` (team S6PVT5UP7G) to internal TestFlight, then `pilot` adds it
  to "Beta test external" and sends it to Apple's beta review.
- **Android** goes to Play internal testing, then the same version code is promoted to open testing.
- Production and the App Store are never touched. Numbers: `~/.config/aroundwarsaw/release-numbers`
  and the stores' own, the higher wins.

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
