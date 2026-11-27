- The drift practice now happens inside the National Stadium: red and white stands full of fans (phones lit at night, a wave when you bank a drift), LED boards with made-up sponsors, two grass islands with stages, screens and flame jets that fire when you hit a zone, a track wall with tyre stacks, and floodlights at night.

## Backlog
- found: the drift stadium's own sounds are still missing: a flame jet's whoosh (SHOT `zone_flame`) and a crowd roar on a bank wait for make_sfx.py, as the kick, bank and loss sounds already did
- found: in the iso camera (view 34 m, pitch 40°) the stands show only at the floor's corners and edges; the bowl reads in WIDOK Z GÓRY and in `--drift=osemka:bot:wide` shots. A lower or wider drift camera is a feel change for F after the phone (PHONE-CHECK 15zzdrift2)
- fixed (PR review): the board words broke up in the iso view ("TURDO TUR"): a texel was under one render pixel with nearest sampling. Each board is now as long as its words at 0.165 m a texel (a screen 0.155 m), two or more render pixels a texel at High, cropped to its words; the stages show one word a line on two lines; `check_drift` V7 holds the density
- fixed (PR review): the stadium's floodlight no longer flashes the last visit's energy on entry and lights only the floor, the wedge, the marks and the stadium's car (its own render layer); the crowd's bounds take the wave; the stands' cells fade to their mean colour where they are under two pixels (no sparkle in wide views); the tip card goes on the first thumb press
- fixed (PR review): the frame note checks the budget (main pass ≤ 20, shadow pass ≤ 8, no shadow caster but the car) and errors on a breach; `check_drift` V1 samples triangle centres and edge middles, V5 pins the flames 16/8/4
- found: the track wall's banners are plain blocks in each sponsor's colours, no words (at 1 m high a word would be under two pixels a texel); a taller banner fence with words is the alternative
- found: Low and Medium draw one step coarser, so a board's texel there is about 1.9 render pixels (2.7 at High)
- found: the paddock tent and the inflatable can's sponsor print from drift-narodowy.md section 6 are not built (the can is a plain Turbo Tur orange)

## Roadmap
- ticked: "Side quest: Bokiem na Narodowym (grey box in; the stadium's look, then the event)": the stadium's look is in; the event (PR 3) is next
