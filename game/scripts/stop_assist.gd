extends RefCounted
## The quest stop assist (2026-10-31): one place for how forgiving pickups and drop-offs are.
## F found stopping the car exactly on a quest's point too hard on touch controls, so every
## car stop zone (rescue pickup and hospital, Łuber passenger and door, kebab and słoiki
## doors, the "Na czasie" queue and door, the Leżak depot's unload) shares a bigger ring and a
## looser "stopped", and car.gd brakes the car into the ring by itself (assist_at / assist_reach,
## set every frame by main.gd from the quest on now). Pulling into a job's stand (jobs.gd
## PULL_IN) and racing are not assisted: they start or are a choice, not an errand.

## The ring's radius (m) for every car stop zone (it was 6-7 m, then 9; F, 2026-11-01: 13).
const RING := 13.0
## Slower than this (m/s, ~16 km/h) counts as stopped for a pickup or drop-off (it was 1-2.5).
const STOP_SPEED := 6.0
## The assist's braking (m/s²) as it glides into the ring: firm, well under the brake's 30.
const DECEL := 9.0
## It aims this far (m) inside the ring's edge, so the car comes to rest well in.
const INSIDE := 3.0
## It looks this far ahead (m) for a ring the car is heading into.
const LOOK := 60.0
## Holds the car still in the ring this long (s) at most: every quest hold is shorter.
const HOLD := 2.5
## Once let go, it waits until the car is this far (m) outside the ring before grabbing again.
const LEAVE := 6.0
