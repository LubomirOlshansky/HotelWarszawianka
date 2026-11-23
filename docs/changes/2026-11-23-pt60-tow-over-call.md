- A car stuck against a wall now gets the tow truck button even while a rescue call is ringing; the call comes back after.

## Backlog
- fixed: PT-60 (suspect cause), a ringing rescue call held the context button for good, so a stalled car never got POMOC DROGOWA (main.gd `_stuck_offer_frame`)
- found: PT-60's "no auto-unstick for 340 s" did not reproduce in the cloud: at -941.2,93.6 heading 78 the car is turned out within 2 s with v1, soft, mid and firm (the engine log of the Autopilot run, `car: pinned ... turned out`, would say what held it)
- found: the log now says `stuck offer held back` with the button's owner when the offer is due and the button is taken

## Roadmap
