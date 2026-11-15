- After a job, a race, a rescue or a friend's night ends, the next call or ride request waits 30 seconds, so there is a breath after the result card.
- The same caller no longer phones twice in a row while another friend's call is waiting.

## Backlog
- changed, by F's pick (2026-11-15, "take your picks"): how often the player gets called. After any finish the next call, ride request or walk-up offer (the pontoon, the round-up's depots) waits 30 s (the calls and the walk-up offers waited the call gate's 8 s settle before, and the ride requests did not wait); the same friend no longer calls twice in a row while another's call waits
- fixed: the offer pacer's rules (TD-3 b, F's picks 2026-11-15): variety between callers, a 30 s quiet time after a finish, the rescue call's card holds the other offers as its run does, and the phone bench and a boat ride hold the rescue calls through the director (`missions.paused` is gone)
- found: Bartek's call (the EV tow) does not wait for the call gate's gap and settle as the other friends' calls do (`_ev_free` has no `call_ok`); TD-3 gave it only the quiet time, as before otherwise
