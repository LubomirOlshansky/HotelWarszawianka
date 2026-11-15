# Onboarding: hints, the spotlight and the loading tips

First hour step 6 (the first-hour spec, section 6, accepted by F on 2026-11-15; the Fable
critique's defaults, F 2026-11-15 21:02 UTC). The lane file for this step: what was built, the
numbers to tune on the phone, and what is left.

## The rules (George Fan's)

Eight words at most, in the game's one language. The game never pauses for a hint. A hint shows
only to a player who has not done the thing, once (the ring's twice). Never in a race, a chase or
a scripted moment (the message director's CHASE and FOCUS contexts), nor while a card is up.

## The hints in play (`hints.gd`)

| id | words (en) | where the ring is | shows when | goes when |
| --- | --- | --- | --- | --- |
| stop | Slow down and stop in the ring | over the car | into a job's ring faster than 4.5 m/s (~16 km/h), the first two times | the car stands, or leaves the ring |
| reverse | Hold BRAKE to reverse | the brake | 3 s trying to drive in one spot (car.gd `stalled`), before the tow offer at 8 s | the car moves |
| minimap | Tap the map: all of Warsaw | the minimap | free driving after the first pay, 20 s after another hint, the full map never opened | the map opens |
| heli | Roof? Take the helicopter | HELI | a rescue only the helicopter reaches, by car | take-off |
| climb | Hold: up and down | the up pad | the first flight | the up or down pad (or key) is used |
| land | Land by the person | over the helicopter | flying within 120 m of a roof rescue's person | the pick-up |

Each hint stays 7 s at most. What was shown and two things done (the full map opened, a flight)
are in the save's [intro] section as `hint_<id>`, `hint_map`, `hint_flown`.

Left to other steps: "the list glows" on the first map open (step 4's one list), "what next" (step
3's guide), the rival's name tag and RACE button (step 5, built), the tow when stuck (built
before, G14: POMOC DROGOWA on the context button at 8 s).

## The spotlight (`hud.gd` `spotlight`)

One pulsing ring and its words, drawn on the pad canvas like the ghost finger: no node of its own,
nothing drawn when no hint is up. Targets: the minimap, HELI, the helicopter's up pad, the brake,
or the car (words over it, no ring). The words go on the side of the screen's middle and keep in
the safe area; their room is taken from the bubbles while they are up.

## The loading tips (`title.gd`, `data/tips.json`)

One line under the prompt, a new one every 4 s while the city builds; the last stays under TAP TO
DRIVE. Sixteen tips, twelve words at most, four Warsaw jokes to twelve game facts. A tip has the
`tag` of what it tells about; main.gd hands the title the tags this save has done
(`Hints.done_tags`: a job delivered, a rival raced, the map opened, a flight) and those tips go
last. The same list is DŹWIĘK → PORADY in Settings, so a tip that flashed by is not lost.

## The DEV page (`settings_panel.gd` `_dev_page`)

The Fable critique's beta settings: testers keep their preferences, our A/B switches move out of
their way so every tester drives the same car. Seven taps on the version under the settings
card's title (each within 1.5 s) open the DEV page; once open in a run, one tap does. On it:
the follow camera, handling and the lane assist; the 20 km/h zones, collisions and smashable
fences; the city's chattiness, the performance overlay and TEST. Experimental quality shows on
Obraz only once DEV was opened. The keys are the same as before, so saved values carry over.
The version is project.godot's `application/config/version` ("0.1", as the export's short
version).

## Tuning on the phone (PHONE-CHECK 10e, 10f)

- 4.5 m/s for "stop in the ring": too eager, or too late to matter?
- 3 s for "reverse": before the player gives up, after a normal three-point turn?
- The ring's pulse and the words at phone size, over a sunny street and at night.
- Four seconds a tip: enough to read twice?
