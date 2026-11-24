- Nothing for players: the beta release script exports the iOS build with the Xcode sign-in again, and waits for Apple to list the build before sending it to external testers.

## Backlog
- fixed: build 16's `exportArchive` failed with "Cloud signing permission error ... No 'iOS Distribution' signing certificate" because `tools/release.sh` passed the App Store Connect API key (App Manager role) to it; the key stays for fastlane and the archive step only
- fixed: `--promote` failed when Apple had not processed the build yet; it now polls up to 40 minutes
- checked: no build-16-only gate exception is left (`tools/release_known_red.txt` has no entries)

## Roadmap
- ticked: none (release tooling)
