- A friend's call no longer rings with nothing on the screen: the phone always shows, wider when the invitation is long, and its clock tells the game's time. Offers and quiz cards always show too.
- A rescue call left waiting on its button no longer keeps your friends from calling.

## Backlog
- fixed: a call, an offer or a quiz card that found no room in the HUD stayed hidden (F on the 16 Pro Max, build 15: Darek's call by day, with the night line and the invite; the Smolna clip's Mati offer and bouncer quiz at 16:9 and 19.5:9 with the pedals: a card with the quest's status line up). An unseen call counted as turned down, so the next waited 5 minutes
- fixed: the call card's clock showed the device's time
- fixed: a rescue call waiting on the WEZWANIE button (it waits until pressed) held back every friend's call for the whole drive (about 7 minutes on the Mac: one rescue call, one ride request, no friend); it holds them 45 s now, then the friend who rings puts it off
- found: the trend job's own calls still wait while WEZWANIE waits (`call_waiting`)
- found: with the nitro owned on a 667 pt screen or a 16:9 window a long call stands over the car's spot (`hud.forced()`), as no column has room; only the 12 s it rings

## Roadmap
- ticked: "Every call, offer and quiz card is on screen at phone size (check_call_cards)"
