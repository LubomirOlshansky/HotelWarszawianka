- The beta now counts anonymous play stats (sessions, play time, jobs finished, frame rate) to see what to fix next; Settings → Dźwięk → "Anonimowa statystyka" turns it off.

## Backlog
- fixed: the beta had no way to know how many people play, whether they come back or how long they play (F 2026-11-15): play_stats.gd with PostHog EU, anonymous ID, white-listed events, an off switch, docs/STATS.md
- found: PostHog's Godot SDK is marked experimental and unverified on real iOS/Android devices: check the first TestFlight build's events arrive (docs/PHONE-CHECK.md)
- found: Play's Data safety form and App Store Connect's App Privacy answers must be changed by hand before the next build is submitted (docs/store/*)

## Roadmap
- added and ticked: anonymous play stats for the beta (PostHog EU, off switch in Settings)
