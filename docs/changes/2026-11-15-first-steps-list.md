- A new "First steps" list of seven things to try in any order (a kebab, a lift, a race, a rescue, the helicopter, the police, Mirek's garage): each one ticks with a small reward, the third brings a new paint, all seven a card.
- After your first delivery the game asks once what you feel like (race, rides, fly, or just drive), then introduces only what you have not tried yet, when you are free, instead of on a timer.
- Friends start calling once you know the basics (three first steps, or twelve minutes), one new friend at a time.

## Backlog
- fixed: the first ten minutes fired every beat by the clock and told a player who had already flown about the helicopter (the spec "First hour for the beta", step 3)
- fixed: the Spacer offer could come in the second minute and switch off the whole first hour (now after three First steps)
- found: the First steps list has no place on the map yet; step 4 (one map list) reads `first_steps.gd rows()` for it
- fixed: JUST DRIVE is the card's ✕ (hud.gd `set_card_close`, step 6's #866), not a fourth button

## Roadmap
- adds: "First hour for the beta: step 3, the First steps list, the choice card and the friends waiting for three steps" (ticked)
