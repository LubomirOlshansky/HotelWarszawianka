- Fences and hedges now break when you drive through them, bumps keep more of your speed (the Medium collision answer), and the test switches are one tap away in Settings.

## Backlog
- fixed: F 2026-11-16 for TestFlight build 12: smashable fences on and the collision answer Medium (mid) by default; an older settings file (no `collide_default` key) gets both once, then keeps the player's choice; Settings → Jazda has an "OTWÓRZ DEV · OPEN DEV" button (the seven taps on the version still work)
- found: a `--nosave` run (the checks, the drive logs, the bench) keeps the old measured defaults (hard fences, v1) unless `--soft` or `--collide=` asks, so the baselines stay comparable; the phone's own runs get the new defaults
