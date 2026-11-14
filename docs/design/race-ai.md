# Race AI: the audit, the new design and the race bench

**To tune or change the racers, start with [race-ai-tuning.md](race-ai-tuning.md):** every knob,
where it lives, how to test a change and the known traps. This document is the why and the
history.

**Status (2026-11-12):** steps 1 to 4a of 8 are built. Step 1 was the race bench, the prototype
race and the recorded baseline of the old driver. Step 2 took the rubber band out: every rival
drives its own skill from the line to the finish, whatever the player does
([section 6](#6-difficulty-from-skill-and-the-personalities)). Step 3 gave every rival a plan:
its streets by its own seconds to the finish with the town's traffic counted, another way round
a blocked street, no empty streets once the player is out of sight, and one finish line for both
cars ([section 5.1](#51-step-3-as-built-the-plan-the-way-round-the-towns-traffic)). Step 4a gave
it a racing line and a speed for every metre of it: a rival brakes before a bend and takes it
inside the grip of the player's own car
([section 5.2](#52-step-4a-as-built-the-racing-line-and-a-speed-for-every-metre)). Passing,
contact and recovery are still the old rail car's, for step 4b. The build order is in
[section 8](#8-build-order).

Written from F's note of 2026-11-09 (two phone screenshots of the race against Pani Halina from
Powiśle to Plac Trzech Krzyży): "she was still going very slow, and like the mob, not behave like
real racer and competitive". F sent a friend's advice with it, six points:

1. racers get their own driving rules (overtake, cross lanes, cut corners, take a shortcut
   wherever the player can) and still respect collisions and handling;
2. the shortcuts are in the racers' map: alleys, courtyards, car parks and gaps, each with the
   car's width, turning room, grip and obstacles accounted for;
3. a route is chosen by expected arrival time: driving time + traffic delay + a risk penalty that
   each racer weighs differently;
4. choosing the route is apart from driving the car, with explicit recovery (reverse, turn,
   re-route) and a brief commitment to an overtaking side;
5. recognisable personalities (a local expert, an aggressive challenger, a careful veteran);
6. difficulty comes from skill (reaction, cornering accuracy, route knowledge, risk) while the
   acceleration, grip and collisions stay those of the car.

"The first prototype should be one race with three useful routes. Test it with clear roads, heavy
traffic, a blocked shortcut, and a crash. Check whether opponents finish reliably, pass slower
cars, recover, and choose sensible alternatives. Expand that system across the city once it
works." And F: "racing is the big part of the app, there are other racing quests and should be
more ... if we need to build something progressive and reliable we should do that."

This doc replaces the driver and the rubber band of [street-races.md](street-races.md) (its R1,
R2, R4 and the routes of R3). That doc's "show the race" (R5), the city's reactions (R6), the
race kinds (R7) and the leaderboard (its section 8) stand.

1. [What is wrong today](#1-what-is-wrong-today-measured)
2. [Why the last fix did not change what F saw](#2-why-the-last-fix-did-not-change-what-f-saw)
3. [The weak places](#3-the-weak-places)
4. [Every race in the game](#4-every-race-in-the-game)
5. [The new design](#5-the-new-design)
6. [Difficulty from skill, and the personalities](#6-difficulty-from-skill-and-the-personalities)
7. [How we test it: the race bench](#7-how-we-test-it-the-race-bench)
8. [Build order](#8-build-order)
9. [Parked questions](#9-parked-questions)

---

## 1. What is wrong today (measured)

*Sections 1 to 3 are the baseline of 2026-11-09, before step 2: the driver F raced. They stay as
the record of what was wrong. What step 2 changed is in
[section 6](#6-difficulty-from-skill-and-the-personalities), and the marks before and after it
are in [section 7.4](#74-the-marks-today).*

**A rival's speed is a function of the player's.** In a ladder race the rubber band
(`rivals.gd` `band_mult`) scales the rival's top speed by the gap to the player, down to 0.30 of
it for Pani Halina; in the guided first race `first_speed` paces her off the player's own
progress along the route, down to 0.2 of her top. The slower the player drives, the slower she
drives, so she reads as traffic.

The race bench (section 7) runs F's race, Pani Halina from Tamka in Powiśle to Plac Trzech Krzyży
(1752 m by road), with the game's own traffic and race code and a test player in the player's
place. Clear roads, today's driver:

| Test player | Halina's time | Mean speed | What she did |
| --- | --- | --- | --- |
| none | 73.7 s | 84 km/h | flat out all the way |
| never leaves the line | 180.4 s | 34 km/h | 12 s sprint, then 0.30 of her pace: 124 s under half the road's speed on free straight road |
| slow (`--ghost-pace 0.5`) | 179.8 s | 34 km/h | the same |
| average (`--ghost-pace 1.8`) | 110.3 s | 56 km/h | sits just in front, drops to 0.22 of her pace, the player wins by 0.8 s |
| fast (`--ghost-pace=racer`) | 78.5 s | 79 km/h | the player wins by 2 s |
| follows 15 m behind her | 84.4 s | 73 km/h | eases to 0.53 of her pace with the player on her tail |

The same car on the same empty streets takes 74 s or 180 s, and the only difference is the player.

**The ladder's difficulty is the band, not the driving.** Flat out with no player the six rivals
are within 6 % of each other, and the second rung is slower than the first. What separates them is
how far the band lets each one drop:

| Rival (ladder order) | Flat out, no player | With a player who never moves | Lowest pace |
| --- | --- | --- | --- |
| Pani Halina | 73.7 s | 180.4 s | x0.30 |
| Słoik z Radomia | 76.2 s | 181.3 s | x0.39 |
| Bulwar Bartek | 73.7 s | 105.1 s | x0.58 |
| Seba z Pragi | 72.8 s | 94.2 s | x0.67 |
| Taksiarz Zbyszek | 72.3 s | 89.6 s | x0.72 |
| Mordor Mike | 71.7 s | 85.0 s | x0.77 |

**The guided first race copies the player.** With no player she drives at 0.64 of her pace
(104.5 s). With an average player she finishes 0.2 s behind the player (113.9 s): the scripted
narrow win. With a slow player she takes 285 s, 69 s of it in one crawl on a free straight road at
0.11 of her pace. With a player who never moves she waits 12 s at the line and then stands behind
the player's car for good: Tamka has one lane one way, and she has no way round. With a fast
player her time drops by a quarter (76.8 s). From the second start (Leszczyńska) the same average
player loses.

**The driving under the band has its own faults.** With no player, so no band at all:

| Situation | What happened |
| --- | --- |
| Busy traffic | 137.8 s (45 km/h). She drove through 8 cars, was stopped dead by the game 5 times (from 65 km/h to half the speed of the car in front in one frame, traffic.gd: her own brakes stop at 10 m/s²), was moved through a queue 3 times in view, stood 8.7 s, and 2 of the town's cars passed her |
| Her street walled off | She drove through the wall (Leona Kruczkowskiego, 40 s in). The other way round is 2223 m against 1752 m |
| A wreck in her lanes and a knock | Fine: round the wreck and back from the knock, 2.8 s lost |
| The car's limits | 99 km/h through the 48° bend on Książęca (358, 429): 76 m/s² sideways, the player's car holds 19. A bend inside a street is taken at full speed; only a junction's curve slows a racer, and not always: 96 km/h through 55° in a junction of Plac Zofii Wóycickiej (488, -220) |
| Route choice (from Leszczyńska, three routes) | Her own choice 91.2 s, forced by Dobra 94.4 s, by Topiel 93.1 s, by Solec and Ludna 106.2 s: sensible on clear roads, where the shortest way is the fastest. In traffic 161.5 s against Topiel's 160.3 s |

The whole baseline (every race's numbers) comes from `tools/race_bench.sh`; the marks are in
[section 7.4](#74-the-marks-today).

## 2. Why the last fix did not change what F saw

PR #603 (2026-11-09, "Rivals as fast as the player's car") changed two things and kept the band:

- **Top speed.** Every rival got the player's car's top speed. The band still multiplies it by
  0.3 to 0.5 for most of a race, so the higher top shows only in the 12 s opening sprint.
- **A skilled-player read** (`skill_of`). The band lets go as the player's average progress
  along the route rises from 0.45 to 0.62 of the car's top, 49 to 67 km/h. City driving with
  traffic and lights gives 25 to 45 km/h, so the read stays at zero for a normal player. It
  rewards a player who is already fast and does nothing for one who slows down to watch her.

F's two screenshots fit the guided first race: 37 m in front at 19.7 s while F stood still, 14 m in
front at 58 s with F at 9 km/h. That race's code holds her `FIRST_LEAD` 30 m in front at the
player's own pace with a floor of 22 km/h, and races her off only once she is 150 m ahead.

The tests did not catch it. Each race test used one test player at a fixed speed that never
waits, follows or stops, and the only pass mark was who won and by how much. A rival doing
30 km/h still wins by 561 m against a slow test player, so the check stayed green.

## 3. The weak places

Worst first. "Step" is the build step of section 8 that fixes it.

| # | Weak place | What the player sees | Step |
| --- | --- | --- | --- |
| 1 | Speed is tied to the player. The band aims Halina 15 m behind the player (30 m in front in the guided first race) and can cut her to 15 % of her top speed | She crawls when you are slow, waits when you stop, lifts off before the finish | 2 (done) |
| 2 | The driver is a rail car. It can only slide between lanes, and it passes only into a free lane or an empty oncoming lane | It queues behind slow cars like traffic. After 1.5 s stuck it drives through the car in front | 4b |
| 3 | It plans its speed for the next junction only. It does not brake for bends along a street or look past the next corner, and its brakes stop at 10 m/s² | It arrives too fast: 99 km/h through a 48° bend, or stopped dead by the game behind a car | 4a (done; the dead stops: 4b) |
| 4 | Corners follow the middle of the lane. There is no racing line and no cut apex | Slow, square corners | 4a (done, inside its own lane; the whole road: 4b) |
| 5 | The route is the shortest in metres on legal streets, fixed at the start. Time, turns, lights and traffic play no part, and there are no alternatives | Every rival takes the same streets. Nobody reacts to a blocked road | 3 |
| 6 | Shortcuts are 600 straight hops between two junctions, 160 m at most. Courtyards, car parks and alleys with a real shape are missing | On F's race the shortcuts change almost nothing | 5 |
| 7 | There is no recovery. A blocked racer waits, then passes through the obstacle | It never reverses, turns round or re-routes | 4b |
| 8 | Personalities are numbers on one behaviour | Seba and Halina drive the same way at different speeds | 6a |
| 9 | Traffic only exists near the camera | A rival out of sight meets no cars and gains time for free | 3 |
| 10 | Each race mode has its own copy of the glue: the ladder, the pack race, police chasers, crazy drivers | A fix in one race does not reach the others | 6b |
| 11 | The tests use one fixed-speed test player and only check who won | A rival doing 30 km/h passes the test | 1 (done) |

## 4. Every race in the game

Six race modes put a car against the player, and four of them share the weak driver. The rebuild
gives them one driver and one race object, so a fix lands everywhere.

| Race | Opponents today | After the rebuild |
| --- | --- | --- |
| Street race ladder: Pani Halina, Słoik z Radomia, Bulwar Bartek, Seba z Pragi, Taksiarz Zbyszek, Mordor Mike, to 11 finishes (`rivals.gd`, `ladder.gd`) | Rail racer plus the band, a share of the 600 shortcuts each | New driver, a skill profile per rival, routes by time |
| The guided first race with Pani Halina (`rivals.gd` `first_speed`) | A special band: she holds 30 m in front at the player's own pace, then lets the player catch her | Same driver, on her gentle day (section 6); the script is gone since step 2 (parked question 1) |
| Trzy mosty, the ladder final against Seba | Rail racer with a weak band | New driver, the long route over the three bridges |
| Night club pack race (`street_meet.gd`) | Several rail racers at full speed with every shortcut, no band | Same driver, one race object for the whole pack: done since step 6b part 1 (6.2) |
| Police chasers (`police.gd`, `police/chase_route.gd`) | Rail racer that never passes the player | The driver with a chase goal: a plan toward the player, the racing line, honest braking; done since step 6b part 2 (6.3). The search, the escort, the blockers and the roadblocks still drive the old way |
| Crazy drivers (`crazy_drivers.gd`, `crazy_route.gd`) | Rail racer with no route | The driver with an aggressive profile, driving fares across town: a plan, the racing line, honest braking; done since step 6b part 3 (6.4) |
| Drag race at the night club | A simulated run, no driving | Stays |
| Courier bike race | Its own rider on the footways | Stays, may share the route planner later |
| Boat race on the Vistula (`boat_race.gd`) | Its own boat driver | Stays |

Since step 2 the ladder races, the guided first race and Trzy mosty have no band: each rival
drives its skill profile, with an effort that follows the time gap (section 6). The pack race,
the police chasers and the crazy drivers never had one. Since step 6b part 1 the pack race drives
the new driver too, on the same race session (6.2), since step 6b part 2 a police car in a
chase drives it as well, on a session of its own (6.3), and since step 6b part 3 so do the crazy
drivers, a session each (6.4). Every race mode drives the new driver now.

Normal traffic keeps its rail and car-following model (IDM). That model is right for traffic.
What changes is that racers treat traffic as moving obstacles with a predicted path.

## 5. The new design

Four layers that each do one job, one profile that makes Halina differ from Seba, and one race
object shared by every race mode.

```
RaceNav      where a car can go: the lane graph + race links (width, surface, risk)
   |
RacePlanner  which streets: seconds to the finish from everywhere, per racer
   |
RacePath     the line on those streets and a speed for every metre of it
   |
RaceDriver   follows the line among other cars: overtakes, collides, recovers

RacerProfile the same car as the player's; skill, knowledge, risk, temperament
RaceSession  one race: the grid, the racers, the ranking, the result (every race mode)
```

- **RaceNav, the race map.** Today's lane graph stays the base. Race links add what a car can
  drive and the graph lacks: the 600 existing hops, then alleys, courtyards, car parks, gaps, and
  short wrong-way hops on one-way streets. A link carries its width, surface and risk, and ships
  only after the player's physics car has driven it in a test. The rule: a racer can go only where
  the player can, and the player can go wherever a racer goes.
- **RacePlanner.** A street costs the seconds this racer needs to drive it, plus the expected
  traffic delay, plus risk weighed by the racer's caution. One search from the finish gives the
  time to go from every street, so a new plan after a block is cheap. A racer changes route only
  for a gain of 3 s or more, so it does not dither.
- **RacePath, the racing line and the speed.** The next 300 m of streets become one line inside
  the free width of the road, smoothed to open up the corners. Every metre gets a top speed from
  its bend and the car's grip. A backward pass then makes the racer brake in time for the second
  corner while still in the first.
- **RaceDriver.** A racer leaves the rails. It has a place along the line and an offset from it,
  so it can use the whole road. Every frame it predicts the cars ahead and scores three options:
  stay, pass left, pass right. It holds its choice for about 2 s. Touching another car is a
  collision that costs both cars speed, never a pass through. Stuck for 1.2 s, it tries the other
  side, reverses 6 m, tries again, then re-routes; a rescue by the game happens only out of sight.
- **RacerProfile.** Every racer has the top speed, acceleration, braking and grip limits of the
  player's car. What differs is how much of them the racer uses, what the racer knows and what
  the racer dares.
- **RaceSession.** The grid, the racers, the ranking and the result for the ladder, the first
  race, Trzy mosty, the pack race, the police chasers and the crazy drivers. Built in
  step 6b part 1 as `game/scripts/race_session.gd` (6.2): the mechanics only (course, racers,
  plans, start, legs, effort, order, reroutes, lights, end); the words, cards and pay stay in the
  race mode's own script. The ladder races, the guided first race, Trzy mosty, the night club's
  pack race, the police chasers (6.3), the crazy drivers (6.4) and the race bench run on it.

**Rejected.** The player's physics car for rivals: the buildings' walls exist only near the
player's car, so a physics rival far ahead would drive through houses or need the whole city
loaded. The racer obeys the same limits in numbers, and a hit between a racer and the player
stays physical. A speed rubber band of any kind: it is the fault. Rewriting traffic: its rail and
car-following model is right for town cars and cheap for 60 of them.

**Add-ons.** Beehave and Dialogue Manager are not used: the driver is a per-frame scoring of
three options with a short commitment, not a tree of authored states, and nothing here is a
conversation.

### 5.1 Step 3 as built: the plan, the way round, the town's traffic

Step 3 (2026-11-12) built the RacePlanner and gave the old driver the three things it needed to
obey a plan: asking it at every junction, turning back at a blocked street, and paying for the
town's traffic where the town's cars are not. The driving itself (the rail car, its passes and
its corners) is still the old one, for steps 4a and 4b.

**The plan** (`game/scripts/race_planner.gd`). One `RacePlanner` for the map knows every way
through every junction (8,982 in the centre) and its curve. A race gets a `Plan`: one search back
from the finish gives this racer's seconds to the finish from every street. A street costs:

- its metres at the racer's own speed there (its `share` of the road's racing speed), up from the
  speed it left the last corner with (`race_accel`) and down to the next corner's (`brake`);
- the junction's curve at the speed its grip gives it (`lat`). A turn tighter than a car turns (a
  U-turn, or a hairpin onto the other carriageway) is the arc of a 5 m circle at 3.5 m/s, so no
  plan takes a U-turn for a third of a second;
- its lights: about half of them red, run a little slower;
- a shortcut the racer knows (`race_cuts.gd`), a way on from the junction like any road;
- the town's traffic as far as the racer knows it, and its caution on a street with no way past
  (below).

At every junction the driver asks its plan which way is quickest from there (`Plan.choose`), so a
wrong turn or a shove needs no new plan: the table already holds the time from that street. It
leaves the way it held only for a gain of 3 s. On clear roads the plan's clock is within 3 % of
the race as driven (Halina from Tamka: 101.1 s planned, 99.2 s driven), and `check_race_planner`
holds it to 6 %.

Six rivals get six tables from one map. On clear roads they mostly agree on the streets and
differ in the seconds. In traffic they part: from Leszczyńska to Plac Trzech Krzyży in Busy
traffic Halina, Bartek and Mike plan Zajęcza and Topiel, Seba and Zbyszek go by Dobra, and Słoik,
who does not know the town, keeps the clear roads' way by Jaracza.

**A wrong turn** (Słoik) comes from the plan too: a road that costs him 4 to 15 s more than his
best way, and never the way back. The old rule took the second shortest road in metres. With a
plan to bring him back that cost him a second or less, and on the bench he came home in front of
Bartek.

**One finish line for both cars** (`RacePlanner.ends`, `Rivals.home_at`, `traffic.gd`
`end_from`). A street race ends when a car comes within 16 m of the finish (`FINISH_RADIUS`), and
the finish in the lane graph is one junction. At 8 of the 11 finishes another road runs through
that circle, 12 roads in all: the other carriageway of Emilii Plater by the Palace, the ring of
Rondo Dmowskiego, Aleja Jana Pawła II by Varso and at Rondo ONZ, Złota by Złote Tarasy, Aleje
Jerozolimskie's viaduct at Dworzec Powiśle, the bridge and its avenue at the east end of Most
Poniatowskiego, a service road by the stadium. The driver knew only the junction, so on such a
road it was home only when its lane happened to be the one inside the circle (by the Palace, one
of Emilii Plater's three). From Marszałkowska to the Palace step 2's Halina was home at the
circle in 9 of 14 bench races; in the other 5 she drove on past the Palace and 500 m round to
the junction, half a minute more (94 to 118 s where the same races now take 62 to 89 s). A plan
to the junction made that the rule: it counted 101 s and 1,523 m for a race of 66 s and 995 m,
and in Low traffic it chose a way to the junction that never crossed the circle. The player had
the same lottery: in an outer lane the car passed the beacon and nothing happened.

Now a finish is one line for both cars. `RacePlanner.ends` finds, once per finish, the roads
through its circle other than the junction's own. A road counts when one of its lanes comes at
least 1 m inside the circle on the finish's own level (within 3 m of height: the riverside road
8 m under the east end of Most Poniatowskiego is another level's road and stays out). On such a
road the finish line runs across the carriageway where the road enters the circle, in whichever
lane:

- the plan's search starts from each of those roads at its line as well as from the junction,
  so the plan's seconds, the driver's choice at every junction and the metres left
  (`Plan.metres`; `RacePlanner.links` gives the routing of the HUD's metres the same ends) all
  end where the race does, and the rival is home at the line (`arrived`);
- the player's car is home inside the circle as before, and on such a road level with the circle
  in any lane (`Rivals.home_at`: within 5 m of one of that road's lanes and at its height, so not
  from the pavement beside it and not from the street under a bridge);
- the minimap's route ends at the line (`route_line.gd`), and the lose card's metres short are
  counted to it;
- past the circle on such a road nobody is home, and the plan sends the rival round.

The Palace races now: 60 to 72 s on clear roads and in Low and Normal traffic, 71 to 89 s in
Busy traffic, all 14 home at the line after the route's 970 to 1,000 m. Trzy mosty's finish by
the stadium is such a circle too: the avenue's other carriageway runs through it 132 m after
the last bridge, where the finish's own junction is 682 m round. On main Seba's way to that
junction left the avenue by the slip road and came back up by the stadium's service road,
never nearer than 27 m to the finish before its last street, and the minimap's line led the
player the same way; but a player who drove straight on in the avenue's left lane (14 m from
the finish; its other two lanes pass at 17.5 and 20.7 m) was home 550 m sooner. Seba's last
leg is now planned to the circle (5 s from the bridge against 30 s), and the line and the
metres end there: in the whole game, started at the last bridge, he is home in 26.7 s where
he took 51.1 s. `trzy_mosty.gd` picks that finish for a last dash of at least 400 m by road
(`FINISH_MIN`), counted to the junction, so the dash is now 132 m for both cars (BACKLOG).
The final's checkpoints keep junction plans, because a checkpoint is driven
through. At the three finishes with no other road through the circle (the Palm, Plac Trzech
Krzyży, Kopernik) the plan is the junction's plan state for state, and the bench's other 107
races came out the same in every number. In the whole game's first ten minutes Halina plans
71 s to the Palace (109 s to its junction) for a race the autopilot won in 68.0 s.

**The search costs** 12 to 55 ms by the length of the race (65 ms for the whole map), so it never
runs in one frame. `rivals.gd` searches 150 ways a frame (0.6 ms on a desktop, 1.5 ms at worst)
from the challenge on: a plan is ready in at most 52 frames of the 5.6 s before the start. In
Trzy mosty each leg has its own plan, searched while the leg before is driven. A choice at a
junction is a look in the table (3 millionths of a second). A race called before the game has
set its traffic level (`--race=`) plans again once the level is in.

**A blocked street** (`traffic.gd` `BACK_*`, the signal `turned_back`). Blocked is a wall of
parked cars across every lane both ways, seen from 40 m, or the player's car standing in the
racer's only lane for 3 s. The racer tells its plan (`Plan.block` shuts the street for the race
and searches again in slices), stops 5 m short and turns back as the player would have to. In a
two-way street it makes a U-turn where it stands, at 3.5 m/s, once the oncoming lane is free. In
a one-way street it backs out to the junction behind at 7 m/s at most (the player's car's own
reverse), keeping 3 m from any car behind, backwards through the junction's curve onto the road
it came by, and goes on from there. Two racers in one blocked street back out one after the
other, and the first out makes room for the second. A racer boxed in behind as well for 6 s does
what a racer without a plan does (the game slips it through, counted against No ghosting). It
turns back three times a race at most. `rivals.gd` counts the metres it has left without the
shut street (`traffic.reroute`), so the gap on the HUD stays true.

**The town's traffic in the plan** (`Traffic.race_delay`). The friend's "route score = driving
time + traffic delay + risk penalty". The delay is measured, not guessed:
`tools/race_traffic.sh` drives three rivals over ten courses at Low, Normal and Busy traffic
against the same streets on clear roads (252 races, 8,220 streets) and fits

```
delay = density x (share x length x max(1/10 - 1/v, 0) + 0.25 + 1.5 x lights)   seconds
```

where `v` is the racer's own speed on the street (m/s), 10 m/s the speed behind a town car, and
`share` the part of the street spent behind one: 0.77 on a one-lane one-way street (no way
past), 0.24 on a one-lane street with an oncoming road to pass on, 0.39 on a street with several
lanes. `density` is the game's traffic level (0.22 Low, 0.38 Normal, 1 Busy). Measured, a
kilometre of the centre costs Halina 6.3, 12.3 and 28.3 s at the three levels, Bartek 7.1, 12.6
and 31.8 s, Mike 8.7, 14.9 and 34.4 s: in proportion to the density, and more for a faster
racer, who has more to lose behind a town car. The model gives a race's time in traffic to 6.7 %
(6.8 % for a course left out of the fit), and the town's draw of cars alone moves a race by 5 to
6 %, so little is left to know. Of the delay, 13 % is streets with no way past, 10 % one-lane
streets with an oncoming road, 46 % streets with lanes, 14 % street ends and 17 % lights. The
constants were fitted before the lane was held (below); run again with it, the fit moved to 0.73,
0.26, 0.40, 0.24 and 1.53, no nearer a race's time than the constants as they stand (6.7 %
both), so they stay. Run once more after step 4a (the line, and the pass over the centre line
by the lanes it uses), a kilometre costs Halina 6.9, 12.0 and 27.5 s, Bartek 6.7, 12.1 and
29.5 s, Mike 8.9, 15.1 and 32.9 s; the fit moved to 0.70, 0.22, 0.30, 0.39 and 1.61 and gives a
race's time to 7.5 %, the constants as they stand to 7.6 % (3 % long in Busy traffic), with the
draw alone at 5 to 6 %: they stay again. These are the old driver's numbers: when step 4b
changes how a racer passes, the tool is run again and the constants move.

Two numbers of the racer's profile read it (`ladder.gd`):

- `knows` (0 to 1): how much of the town's traffic it plans with. Słoik 0 (his plan is the clear
  roads' at any hour), Mike 0.4, Bartek 0.5, Seba 0.7, Halina and Zbyszek 1.
- `caution`: how much more it counts a street with no way past (the risk of being boxed in).
  Halina 0.8 (1.0 on her gentle day), Słoik 0.5, Bartek 0.3, Zbyszek 0.2, Mike 0.1, Seba 0.

**Fair out of sight** (`traffic.gd` `AWAY_*`). The town's cars exist only in a band round the
view, so a rival the player had left behind, or one far in front, raced on empty streets: in
Busy traffic Halina came home in 107 s out of sight and in 122 to 131 s among the cars, and
Zbyszek in 83 s against 135 s. Now a racer beyond that band owes each street's delay as it
enters it, and pays by covering less ground: its pace eases to 3 / (3 + seconds owed) of its
speed, at most 0.3 a second, never as a stop. Back among the town's cars the debt is dropped,
because real cars are in its way again. Out of sight all the way Halina now takes 139 s, against
127 to 134 s among the cars. Over the full matrix's 31 races in Busy traffic with a test player,
a rival's time against its time alone went from 15 % faster on average (38 % at most) to level
on average and 7 % either way (16 % at most).

**A lane held for 2 s** (`traffic.gd` `RACE_LANE_HOLD`; the friend's "brief commitment to an
overtaking side", ahead of step 4b because the bench showed it). The player's car is in no
lane's list of cars, so behind it the lane a racer had just left always looked free: it changed
lane and back every frame, never moved over, and followed a slow player down a two-lane road.
In the first race from Leszczyńska with the slow test player Halina sat behind for 35 s. A racer
that has changed lane now stays in it for 2 s before it looks for a lane or a pass again, and
she is past at the first two-lane stretch, 17 s into the race.

**What step 3 leaves.** A racer still cannot pass on a one-lane one-way street: behind the
player's stopped car on clear roads it turns back and comes home another way, but in Busy
traffic the town's cars queue behind it and it has no room to back out (the first race from
Tamka with a player who never moves, in Busy traffic: the one race of the full matrix that does
not finish). That is step 4b's pass on the side. And the plan knows the town's traffic as an
average: it does not see the queue that is there today.

Of the finish: the circle itself is flat (a car on the riverside road under the east end of Most
Poniatowskiego is inside it on the ground and home; only the line across a road looks at the
level). A race's finish is still picked by the metres to its junction (`_pick_finish`: 600 to
1,800 m), which at a finish with a road through its circle is more than the race's own metres.
And the old driver does not move to the lane by the beacon: it is home at the line in the lane
it is in.

### 5.2 Step 4a as built: the racing line and a speed for every metre

Step 4a (2026-11-12) built the RacePath of the plan above and put it under the old driver. The
rail stays: a racer's place along its way is still the lane graph's metres (the street's
stations, the junction curve's length), with its lanes, gaps and lights. Only where the car is on
the ground, and how fast it may be there, is now read from a line. Passing, contact and recovery
are still the old driver's, for step 4b.

**The line** (`race_line.gd`). The town's cars keep to the middle of their lane and to the
junction's curve, whatever their speed: a lane that steps sideways across a junction, a kink in
the street's line and a tight curve are all driven as drawn. A racer's line stays in its own
lane and inside the junction, and makes the best of that room: what is left of the lane beside
the car (up to 1 m a side) and, in a junction, 0.3 m further in than the lane graph's curve.

- A sideways step between two lanes straight across a junction is spread over both streets, down
  a ramp of 5 cm a metre where the street is long enough (8 cm at most).
- Every bend that is left is rounded by the widest arc that stays in the room of each point it
  passes. Bends of one hand close together (the two halves of a turn, the short pieces a big
  junction is cut into, a street's bend drawn as short pieces) become one arc where that is
  wider.
- A U-turn, a hairpin and a shortcut are driven as before.

The line is built a stretch at a time, from the middle of one long street through the junction
(or the run of short pieces a big junction is cut into) to the middle of the next. A stretch
depends on nothing outside it, so it is built once, kept and shared by every racer, and building
the way further ahead never moves the line under the car. Over the whole map that is 13,273
stretches (every lane of every such run), 0.7 ms each to build and 20 ms the slowest
(`check_race_line.gd` builds them all: none leaves its lane's room or its junction's).

**A speed for every metre** (`race_line.gd` `speeds`). The most a racer may do at a place is
the speed at which the turn of the next 8 m of its line asks for its grip: v = √(grip × 8 m /
turn). That is the bench's own measure of an honest car (7.3), so a line driven at its speeds
passes it by construction. A pass backwards over the line then lowers every speed until the
racer's own brakes reach each bend's speed in time: it brakes for the second corner while still
in the first, and for a bend in the middle of a street, which the old driver never saw (it knew
one speed, for the next junction's curve).

**In the driver** (`traffic.gd` `LINE_*`). A racer with a plan (the ladder's races, the guided
first race and the final) drives a line; the town's cars, the police and the races that have no
plan yet (the pack race, the night meet's race: step 6b) drive as before.

- **The way ahead.** A line needs the streets beyond the next junction, so the racer asks its
  plan for them at least 100 m ahead and holds each choice when it gets there. Słoik's wrong
  turn is rolled when the street is decided, a junction or two early.
- **Beside the line.** A pass or a lane change moves the car sideways off its line. It then
  drives the line's own shape that far over: inside a bend its way is shorter and tighter, so it
  covers fewer metres for each metre of the line and gets a lower speed; outside it is longer.
- **A new line.** When the line under the car changes (a lane changed, the plan changed its
  mind) the car moves over from the old one to the new one across 12 m, so its heading has no
  step.
- **No sideways move in a corner.** A racer starts a lane change or a pass over the centre line
  only where its line asks for less than half of its grip. A sideways move on top of a corner
  adds up to more than the car holds.
- **A mistake** (a corner taken badly) is a speed too high for the bend from 15 m before the
  junction's curve to 15 m past it, never more than the player's own car holds (19 m/s²).
- **The pass over the centre line** is still the old driver's (out for up to 4 s, then back
  in), with two things put right that the line brought out. It minds the oncoming lanes within
  2.5 m of the line it drives, which is the lane it is driven in: on a street with two lanes
  each way the far oncoming lane is a lane's width clear of it, and counted too it held Pani
  Halina 15 s behind a row of cars on Książęca. And that lane must be clear for as far as the
  two cars close while the pass lasts and for 0.7 s more to come back in: the 70 m it asked
  for are 2.3 s away when a racer at 70 km/h meets a town car at 40.
- **Backing up.** A racer that backs away from a block drives the lane graph's way: a line knows
  only the way on. (Found on the way: a rival that backed out of a junction's curve and then
  made room for the car behind stood still on screen while the game moved it 12 m.)

**Skill, set again.** With a real limit on the sideways pull the old `lat` numbers were too low
to keep the rivals' times. The old driver's corner speed came from the lane graph's own curve
through a junction and was worth about twice the number as a real pull, and nothing held a bend
inside a street: Mordor Mike went through the 48° bend on Książęca at 101 km/h, 77.6 m/s²
sideways where the player's car holds 19. So each rival's four numbers were set again on the
bench until its time alone on clear roads came back (the table in section 6): within 1 % for
all six and the gentle day, with every corner now inside the car's limit (9.4 to 16.5 m/s² at
the worst place of each of the 44 clear-road races, where the old driver's were 24 to 78). The
fast rivals brake later than before (13 against 9 m/s² for Mike): with honest corners the
braking zone is where a good driver gains. Mike's share of the road's speed went to 1.0, which
left his effort no room on a straight; the same cut number was used for his grip, so his push
did nothing at all (`check_first10.gd` found it). The cut is now for the straight only, and a
corner gets the effort itself. The bench's races came out the same with it, all 110: in none of
them does Mike fall far enough behind a player to push (7.5).

**The plan's clock** still counts a corner by the old rule (the junction curve's radius and the
racer's `lat`), now with the new numbers. Against the race as driven on its line it runs 2.4 to
4.1 % early (`check_race_planner.gd` allows 6 %). On clear roads the routes it picks did not
change. In Busy traffic from Leszczyńska Pani Halina's plan now goes by Dobra where it went by
Topiel: the two are a second apart on her clock (173.8 and 174.5 s), and forced through each
she is quicker by Dobra (173.6 s against 176.8 s; with step 3's driver 181.8 s against
185.2 s). A clock that counts the line itself goes with step 5, where the plan's streets get
their race links (BACKLOG, "Racer AI rebuild").

**What the bench says** (the full matrix's 110 races against step 3; the marks are in 7.4):

- **Corners.** Over the car's sideways limit of 19 m/s² somewhere: 109 of the 110 races before,
  none now. The worst place went from 77.6 to 18.4 m/s², and the middle race's worst place
  from 39.8 to 14.2.
- **Times.** They held: each rival alone on clear roads from Tamka is within 0.6 s of its old
  time, every one of the 44 clear-road races within 2 % (together 4,684 s against 4,692 s), and
  the 47 races in Busy traffic that finish both times are 3 % quicker together (6,735 s against
  6,940 s).
- **Behind a slower car.** The longest wait with a free lane beside it went from 8.2 to 6.2 s,
  and a wait of more than 4 s is in 2 of the 48 races in Busy traffic where it was in 11.
  Passes: 496 (476), of them 104 over the centre line (79).
- **The player's place.** A rival's time moves 13 % with the player at most (16 %), which is
  inside the mark's 15 % for the first time on the full matrix, and 5.3 % on average in Busy
  traffic (6.9 %). The 13 % is close to the spread of the town's draw (below).
- **Contact.** Cars driven through: 150 (152), for 80 s in all inside one (114 s); 37 of them
  came the other way (38). Moved by the game in view: 60 times (79), and never put somewhere
  else (5 times before). Stopped dead by the game: 130 times (140).
- **The quick matrix** is four races in Busy traffic, one draw of the town's cars, and there
  the contact went the other way: 17 cars driven through (5), 6 moves by the game (1), 16 dead
  stops (5), while the longest wait fell from 8.2 to 1.5 s. Traced car by car, they are the
  faults below; the full matrix's 48 races in traffic are the measure.

**What step 4a leaves**, each traced on the bench and each a part of step 4b's driver:

- **A sideways move is still a slide at 4 m/s** that starts and ends in one frame. One swing of
  it costs the car v/2 m/s² in the bench's measure, and the worst place of the whole matrix is
  now such a slide (18.4 m/s²: Słoik pulling out at 80 km/h on Solec). It is under the car's
  limit in this draw and not by construction: two other tries at the pass rule put a slide at
  21 and 22 m/s². Step 4b's sideways move is a smooth S within the grip that ends before the
  corner.
- **The pass is a timer.** It is measured at the speed the racer has behind the slower car,
  though it is driven at up to twice that, and it is held out 0.3 s at a time while a car is
  beside it. So a pass can end at the queue of the next junction (Pani Halina at the end of
  Książęca: from 73 km/h to a dead stop), and from the right lane it goes through a car beside
  it in the left one. Two guards against these were tried on the full matrix and taken out
  again. No pass across a car alongside: 4 cars fewer driven through, and Halina 11 s slower
  alone in Busy traffic, with a wait of more than 4 s in 6 races (Independence at 16 %). The
  pass measured at the speed it gets up to, with its 4 s: the fast rivals had room to pass on
  hardly any street (Mordor Mike alone 135.6 s for 115.2 s, Independence at 20 %). A pass
  needs its length from both cars' speeds and the racer's pull, and a way to give it up.
- **The town puts cars down in the gap.** Its cars appear in a band just outside the view
  (`_try_spawn`), in the oncoming lane too, 60 to 110 m in front of a racer who is out in it
  with the lane judged clear: most of the 37 cars met head-on. They are also put down as near
  as 12 m and a car's length in front of any car, a racer at speed included. Step 4b: no car
  is put down in a racer's way.
- **A car standing across a junction** from another street is not in the rival's lane, so it
  drives into it and is stopped dead by the game (130 times in the 110 races). The bench no
  longer counts the pull-away after such a stop as a crawl (7.3): it is one fault, counted once.
- **The longest wait** (6.2 s) is Pani Halina in the first race behind two cars moving off side
  by side from the lights at the end of Wybrzeże Kościuszkowskie, 20 m before the junction,
  where no pass starts.

### 5.3 Step 4b as built: sight, the sideways move, the pass, the way round

All of it is in `game/scripts/traffic.gd` (the Driver's part for racers; the town's cars drive
as they did, but for the two rules marked "town" below). No new script.

**What a racer sees.**

- *On its street* (`_race_gap`): the nearest car ahead in any lane of its road whose body
  overlaps its own across the road, anywhere from where it is to where it is moving over to.
  Before, it followed its lane's list only, so a car half in the next lane was not there. A car
  alongside it is not in its way (it bounds the move sideways instead, `_side_room`). Over the
  centre line it also sees the oncoming car it would meet within 1.2 s; out there with no pass
  under way it brakes for one in time to stand.
- *At a junction* (`_race_cross`): it looks along its own way (its line, or its lane and the
  junction's curve), 10 m and 2 s of its speed ahead, and along the way of every car round the
  junction that is not of its own lanes, and brakes for a place both would be in within 0.6 s of
  each other. A car that stands with its side in the way it steers round within its road
  (`swerve`). A car on another street's curve into the lane it turns into is seen by where it is,
  no longer by the lane's metres (the two met side by side, or the racer stood for a car that
  waited at another stop line). Before, a crossing car counted only within 7 m: most of the 382
  dead stops.
- *The player's car* on its street is judged like any car: by the street's direction and where
  the two are across it. By its own nose a racer that stood askew took a car beside it for one
  in front, and the two stood for good.

**The move sideways** (`_side_step`): towards a lane, a pass or back, a speed across the road
that rises and falls at 5 m/s², 4 m/s at most and never more than 0.4 of its speed forward, so a
lane change is an S that starts and ends without a jump (the bench measured the old slide as
v/2 m/s² in one frame). Not where its line corners (`_line_busy`, as before).

**The pass over the centre line** (`_pass_start`, `_pass_plan`, `_pass_drive`), only from the
lane by the centre line:

- its length comes from the row of cars in front (up to the first gap long enough to come back
  into), their speeds, and the racer's own pull up to the street's speed and its line's: the
  metres and seconds until its tail is 2 m past the row's nose; no pass longer than 7 s or with
  a bend of its line in it;
- the oncoming lanes it is driven in must be clear for those metres, the metres an oncoming car
  comes meanwhile and while the racer moves back (0.7 s), and 10 m;
- every frame the plan is made again from where it is: while it holds the racer goes on past the
  next car too; when it does not, the pass is given up: behind the car it falls back and comes
  in behind it, with its tail past that car's middle it finishes past that one car;
- a standing queue up to a junction is passed to the junction itself, by a racer on a line that
  runs the lights and does not turn right there across the queue's front;
- (town) an oncoming car sees a racer that is out of its lane and brakes for it; a car whose own
  way goes through a racer that stands waits for it, as long as it waits for any crossing car.

**No car is put down in a racer's way** (town, `_try_spawn`): not on its own street within 25 m
and its braking distance in front of it, and not on the oncoming road within the metres the two
close in 4 s while it is out of its lane. Most head-on meetings and many dead stops were a car
that was not there when the racer chose its speed or began its pass.

**Behind the player's car** (the turn-back fault): a racer turns back only when the player's
car blocks, not when it queues: with a car going its way within 12 m in front of it, or a red
light there, the racer waits as in any queue. On a street with an oncoming road it waits 8 s (a
gap to pass in comes sooner than the way round), elsewhere 3 s. With no way back either (a
one-way street, cars behind it) it goes round the player's car at walking pace, over the kerb if
it must, and back to its lane once past it. This is the last resort and looks like one: at a
standstill the car edges sideways before it rolls.

**The cost of looking.** The look across a junction is taken every other frame (the frame
between uses the last answer); the bench's traffic step with a racer costs 432 µs in the middle
race where it cost 322 (Busy traffic 711 for 524).

**The player's car inside the racer's** (1 m or more into each other, after a bump): not in its
way; the two move apart. Before, each stood for the other for good.

**The knot rule** is the last resort too: a racer stands in a queue like any car and slips
through the car ahead only after 30 s without moving (it was 1.5 s: most of the cars driven
through).

**What step 4b leaves** (each is a line of the change note's Backlog):

- contacts at junctions: two curves from two lanes into one lane side by side, and cars of
  another road at the mouth of a junction (about 80 of the cars still driven through);
- the dead stops that are left are on a street: a car that changes into the racer's lane close
  in front of it, and the last metres of a queue met over a crest of the line's speed;
- Independence in traffic: over 15 % for 13 of 46 pairs (3 of 45 before, with a worse worst); what is left is traffic the player's
  car holds up in front of the rival, and the delay a rival pays out of the player's sight
  (`AWAY_*`, fitted before this driver: `tools/race_traffic.sh` is to be run again);
- one corner is over the car's sideways limit (20.5 m/s² for 19): a 119° turn inside a junction of
  Leona Kruczkowskiego at 32 km/h (seba/ladder/tamka/heavy-s3/none; not traced yet);
- Route sense on the full matrix: in Busy traffic a planned route can be a minute slower than
  another now that a queue costs what it costs a car (one race in this draw);
- the way round the player's car has no body: it does not look at walls, posts or the kerb's
  height.

### 5.4 Step 5 as built: race links through yards, car parks and alleys

The lane graph has no service roads, so a rival could only ever take the streets and the 600
straight cuts across plazas (`race_cuts.gd`). Step 5 adds ways with a real shape.

**Where they come from** (`tools/race_links.py` → `game/data/race_links.json`). The map's service
ways (OpenStreetMap `highway=service`: yards, car park aisles, alleys, driveways) are walked from
a mouth on one street to a mouth on another. A link runs from junction A along the street out of
it to the first mouth (45 m at most), through the yard, out of the second mouth and along that
street to junction B, where it joins B's roads like a cut. It is kept when it is shorter than the
best road route as a racer counts it (a metre of link is `COST` 1.15 m of road and it must save
`GAIN` 12 m on top, by 15 m more at least), when a 2.6 m corridor along its yard part is free of
buildings, walls, fences, hedges, steps, rails, trees, lamps, parked cars and the props of
game/data, and when the ground along it stays within 0.7 m of the straight between its ends'
heights (a rival drives it at that height). The centre's yards are mostly dead ends in the map
data, so the whole map gives 52 links.

**The proof** (`tools/race_links.sh`). The player's own car (car.gd, the physics car) drives
every link in the prebuilt city, along the very curve a rival takes over it, with a careful
driver at 43 km/h at most (`check_lane_drive.gd --links`). A link passes when the car stays within
2.5 m of the curve and touches nothing fixed (a wall, a fence, a post) for more than 3 frames;
it then gets its `proof` (the hash of its points). One the car could not drive keeps why
(`refused`). A rival is handed only a proven link, so a racer goes only where the player can. Of
the 52, 37 passed and 15 were refused (the car strayed from the curve in a tight yard corner in
10, touched a wall in 1, and in 4 the drive found no street into the link or no way on). Verify step
`racelinks-drive` drives every proven link again in the prebuilt city (14 s), so a wall or post
put in a link's way later fails CI; `racelinks` checks the file without the city.

**How a rival drives one.** A link is one curve like a cut's (`RaceCuts.curve`): a chain of cubic
pieces through its points, spaced again 3 m apart so the curve's parameter runs with its metres
(`LaneGraph.bezier` and `bezier_length` take a chain; a cut's single piece is computed as
before). The racing line takes it as a rigid stretch (no line of its own inside a yard), at
`LINK_TOP` 12 m/s (43 km/h) at most and the speed its bends allow at the racer's grip. The
planner counts it by its bends' speeds metre by metre (`RaceCuts.drive_time`). A racer looking
for the player's car ahead on a link looks along its next 30 m, as on a road.

**Who knows which** (`ladder.gd` `yards`, `narrow`). A share of the links, drawn per rival like
the cuts, and the narrowest link (m, its narrowest service way's width) the rival dares:

| Rival | Yards known | Narrowest link |
| --- | --- | --- |
| Pani Halina (and her gentle day) | all | 3.5 m: the wide ones only |
| Słoik z Radomia | none | (his satnav) |
| Bulwar Bartek | 0.3 | 3.0 m |
| Seba z Pragi | 0.6 | 2.8 m |
| Taksiarz Zbyszek | all | 3.0 m |
| Mordor Mike | 0.5 | 2.8 m |
| Seba in Trzy mosty | all | 2.8 m |

The night club's pack race (`street_meet.gd`) has no links yet: it is step 6b's.

**What the bench says**: on the old courses nothing moves: all 271 races of the full matrix come out the same to the second and the street as on main (central Powiśle has no yard a race can go through; the driver's step costs the same, 685 µs against 686 µs a race step on the cloud's CPU), so every mark stands as recorded. The new yard course (Wola, Grzybowska to Rondo ONZ, 12 races) shows the link at work: on clear roads Pani Halina takes the yard and is home in 81.7 s, Taksiarz Zbyszek takes it in 66.2 s, and Słoik z Radomia, who knows no yard, goes round by Krochmalna in 108.7 s; in Low traffic the same (Halina 88.9 to 95.4 s over three draws, Słoik 125.1 to 134.3 s). The new mark "Yard links" holds that (who knows every yard takes a link, who knows none takes none), and the yard course stays out of "Skill ladder", since it measures knowledge, not pace. The bench counts links per race (`links`).

**Not built here.** A link is proven from one street into it and one way on; the other ways in
and on differ only in the junction's curve. The wrong-way hops are 5.5.

### 5.5 Step 5b as built: wrong-way hops on one-way streets

F chose it on 2026-11-13 (question 3 in section 9): Seba and Mike may dart the wrong way down a
short one-way street, when it is empty.

**What a hop is.** A race link of kind `wrong` (`tools/race_links.py`, the same file and the
same proof as the yards): one block of a small one-way street, from the junction at its far end
back to the junction at its start, along its own lane. The finder takes a block when it is one-way
with no lane back, 45 to 150 m long, a `residential`, `living_street`, `unclassified` or
one-lane `tertiary` street (never a main road), nearly straight, with no tram rails, and not
one carriageway of a street with two (a same-named street running the other way within 45 m);
when a street leads into its far end and another leads on from its start; and when going down
it saves a racer metres over the best way round by road, counted like a yard. The whole map
gives 52 such blocks. Many more one-way streets are several blocks long: a hop is one block,
and chains of blocks are not built.

**The proof.** The player's car drives each hop in the prebuilt city along the curve a rival
takes (`tools/race_links.sh`), coming from another street and going on into another: 48 proven,
4 refused (3 with no street into them or no way on in the drive, 1 touched something fixed on
Berka Joselewicza). A rival is handed only a proven one. The drive now never enters a link from
the street the link runs down (it had counted a U-turn out of the one-way street as a way in).

**Who dares** (`ladder.gd` `hops`): Seba z Pragi, Mordor Mike and Seba in Trzy mosty know every
hop; nobody else knows any (Pani Halina "never the wrong way"). A hop is not held to a rival's
`narrow`: it is a street, as wide as its lane.

**Looking first** (`traffic.gd` `_hop_look`, `_hop_clear`). The planner counts a hop like any
link, so a racer who dares plans through it when it is the quicker way. On the way to the
junction where the hop starts, at its braking distance plus 12 m, the racer looks down the
street. It goes only when the street is empty: no car of the town's on it, none parked on it,
none about to turn into it (within its own braking distance of the junction), and not the
player's car on the curve into it. Then the street is the racer's until it is out: the town's
cars that would turn into it wait at their stop line and none is put down on it (`_hop_held`).
When the street is not empty the racer refuses the hop: the plan drops it for the rest of the
race and searches again (`RacePlanner.Plan.refuse`), the racer takes the best other way from
where it is, and the owner counts its metres to go again (`hop_refused`, `rivals.gd`). A racer
never waits for a hop, and never meets a car head on in one. The player's car can still turn
into the street while a racer is in it; the racer then sees it ahead like any car in its way.

**What the bench says.** On the old courses nothing moves: all 284 races of the full matrix
come out the same as on main, field by field (no race there has a hop on its way; a race step
costs 286 µs against 287 µs on the cloud's CPU). The new hop course (Wola, Żelazna to Rondo ONZ,
one 112 m block of one-way Żelazna): on clear roads Seba takes the hop and is home in 82.6 s
(the planner's own count: 81 s with the hop, 96 s without), Mordor Mike in 73.7 s; Taksiarz
Zbyszek (88.7 s) and Pani Halina (116.0 s) go round. With a car parked on the block
(the bench's new situation `parked`) Seba looks, refuses and is home in 102.6 s by road, Mike in
91.0 s. In Low traffic over three draws Seba and Mike took the hop twice and refused it four
times; no car of the town's was on the street while a racer hopped it, and none was driven
through there. Two new marks hold this: **Wrong-way hops** (without the town's cars: who dares
takes it on clear roads and refuses it with a car parked there, the others never; in the quick
matrix, so CI holds it) and **Wrong-way hops in traffic** (no town car met or driven through on
a hopped street, nobody hops who does not dare; it counts the town's cars, so it is recorded as
passed on one machine). The hop course stays out of "Skill ladder". The course's finish at
Rondo ONZ shows the faults already recorded there in traffic (a car driven through on the
roundabout, dead stops on Aleja Jana Pawła II): they are not on the hop and stay with No
ghosting and Honest car.

**Not built here.** Chains of blocks (a one-way street hopped over several junctions). The
planner does not price the chance that a hop is refused: a refused hop costs Seba about 7 s
over the way he would have taken by road from the start, since he finds out at the corner. The
pack race has no links at all (6b). A hop is driven at the height of the straight between its
ends, like a yard, and `LINK_TOP` 43 km/h at most.

## 6. Difficulty from skill, and the personalities

No racer's speed depends on the player's. A rival is hard because of how that rival drives, and
the ladder is a row of drivers. Step 2 built every point here but "fair out of sight", which
came with step 3's route planner.

- **Skill per rival, fixed for the race** (`ladder.gd`). Every rival has the player's car. What
  differs is how much of it the rival uses: the share of a road's racing speed held on the
  straights (`share`), the pull away from a corner (`race_accel`), how early the braking starts
  (`brake`) and the grip used in a corner (`lat`), each at or under the car's own. Halina brakes
  early and corners gently. Mike uses nearly all of the car. Since step 4a `lat` is the real
  sideways pull on the racer's own line
  ([5.2](#52-step-4a-as-built-the-racing-line-and-a-speed-for-every-metre)).
- **Each rival's own dice** (`traffic.gd` `race_rng`). A wrong turn and a corner taken badly are
  rolled on the rival's own dice and happen whether the player is near or not, so they are part
  of its skill and of its time. Before, a mistake was rolled only near the player, on dice shared
  with the town's cars.
- **Effort** (`rivals.gd` `effort_of`). The one thing left of "keeping the race close". It
  follows the time gap to the player and never the player's speed. From 1 s behind to 3 s ahead a
  rival drives its own pace. Further ahead it manages the lead, down to 0.9 of its pace from a
  10 s lead on. Further behind it pushes, up to 1.04 from 5 s behind on, the corners harder too
  and with one and a half times its mistakes. On a straight the push stops at the road's full
  racing speed, which is the car's own: Mordor Mike drives it already since step 4a, so his
  push is all in the corners, where the car still has grip to give (`race_corner`). The effort
  moves at most 0.05 a second. So a rival's whole time moves by about a tenth at most whatever
  the player does, nobody waits, and nobody lifts off before the finish.
- **Fair out of sight** (step 3, `traffic.gd` `AWAY_*`). The town's cars exist only round the
  view, so a racer beyond them pays the delay its streets would have cost, as ground not covered
  ([5.1](#51-step-3-as-built-the-plan-the-way-round-the-towns-traffic)). A rival the player
  leaves behind no longer gets empty streets, and the player's place no longer sets its time.
- **What a rival knows and dares** (step 3, `ladder.gd` `knows`, `caution`). How much of the
  town's traffic its plan counts, and how much more it counts a street with no way past. Słoik
  plans as if the roads were empty, Halina and Zbyszek know every queue, and Halina keeps out of
  the one-lane streets Seba dives into.
- **An easier rematch, not an easier race** (`ladder.gd` `ease_of`). A rival drives 5 % slower
  for each race lost to it in a row, 15 % at most, and a win puts it back. It happens between
  races and never during one, it is saved with the game, and a race given up does not count
  (parked question 2).
- **Halina's gentle day** (`ladder.gd` `FIRST_RACER`, `gentle`). The guided first race, and every
  race against her until the player has beaten her once, so a new player who loses the first
  race never meets a faster Halina. After that win she drives her rung's numbers in a rematch
  (parked question 1).

The ladder as built, with each rival's time alone on clear roads from Tamka to Plac Trzech Krzyży
(1752 m), after step 4a, and the numbers and the time of steps 2 and 3 in brackets. The bench's
Skill ladder mark holds the order of the times, not of any one number.

| Rival | Share of the road's speed | Pull (m/s²) | Brakes (m/s²) | Grip (m/s²) | Time alone |
| --- | --- | --- | --- | --- | --- |
| Pani Halina on her gentle day | 0.65 | 7.0 | 4.0 | 9.5 (5.0) | 108.2 s (108.0) |
| Pani Halina | 0.70 | 8.0 | 4.5 | 10.0 (5.5) | 99.6 s (99.2) |
| Słoik z Radomia | 0.92 | 9.5 (8.5) | 8.0 (5.5) | 11.0 (6.0) | 88.6 s (88.0), his wrong turn included |
| Bulwar Bartek | 0.80 | 10.5 (9.5) | 9.0 (6.0) | 12.0 (7.5) | 87.0 s (86.7) |
| Seba z Pragi | 0.86 (0.83) | 12.0 (10.5) | 13.0 (9.0) | 15.0 (11.5) | 80.2 s (80.3) |
| Taksiarz Zbyszek | 0.93 (0.92) | 12.5 (11.0) | 12.0 (7.0) | 15.5 (10.0) | 75.7 s (75.6) |
| Mordor Mike | 1.00 (0.97) | 13.5 (12.5) | 13.0 (9.0) | 16.5 (11.0) | 71.6 s (71.2) |
| The player's car, for scale | 1.00 | 15 | 30 | 19 | 75.3 s (the fast test player) |

The grip is a real sideways pull since step 4a, on the racer's own line; before, the same
number was worth about twice as much through a junction and nothing held a bend inside a
street. The numbers were set again so that each rival keeps its time
([5.2](#52-step-4a-as-built-the-racing-line-and-a-speed-for-every-metre)). A rival that pushes
(5 s behind the player or more) takes its corners with 4 % more grip, 17.2 m/s² for Mike, and
`check_race_line.gd` holds every racer's hardest grip at or under the car's 19.

Before step 2 the six drove it in 73.7, 76.2, 73.7, 72.8, 72.3 and 71.7 s with no player, and in
180 s to 85 s with a player who never moved. Step 3 moved the times by half a second at most,
but for Słoik (92.9 s before): his wrong turn is another road now
([5.1](#51-step-3-as-built-the-plan-the-way-round-the-towns-traffic)). The easier rematch on the
same race: the gentle day takes 108.2, 113.2, 118.6 and 120.3 s after 0, 1, 2 and 3 losses in a
row, and Mordor Mike 71.6, 74.7, 78.2 and 82.4 s. No rival's share goes under 0.58: with the
easing of a long lead on top that is still over half the road's racing speed, the bench's crawl
line.

**What a slow player meets now.** No honest racer can be slower than about the town's own cars
on a straight: under half the road's racing speed is the crawl F saw, and the bench fails it. So
a player who drives at town pace loses to every rival, the gentle day included, and a player who
races wins. In the whole game the replay of the first ten minutes has a cautious autopilot at
the wheel (about 67 km/h on the straights, the gentle day's own top speed). Its guided first
race to the Pałac Kultury came out three ways in three runs of the same code: she won by 9.1 s,
lost by 10.6 s and won by 2.4 s, in 71 to 80 s. Before step 2 that race took 124 s and the
player won it by 2.2 s, because she waited. So the first race is close for a cautious driver and
easy for one who uses the car: on the bench's race from Tamka the fast test player beats her
gentle day by 32 s. If the first race proves too hard for new players on the phone, the honest
levers are a gentler profile down to the floor, a head start at the line or a shorter race, and
never a rival who waits.

The friend's three types map onto the six rivals. These are starting profiles, to be tuned on the
bench and by F's feel on the phone.

| Racer | Type | Drives | Knows | Dares |
| --- | --- | --- | --- | --- |
| Pani Halina | Local expert | Brakes early, gentle in corners, very steady | Every courtyard and alley in Powiśle and Śródmieście | Wide gaps only, never the wrong way |
| Słoik z Radomia | Newcomer in a van | Quick on the straights, misses turns | Main roads only, like a sat-nav | Little, and the van is too wide for narrow links |
| Bulwar Bartek | Blocker | Average pace, defends his line | The riverside | Closes the door on you |
| Seba z Pragi | Aggressive challenger | Brakes late, uses the most grip, makes mistakes | Praga and the bridges | Narrow gaps, short wrong-way hops, contact |
| Taksiarz Zbyszek | Careful veteran | Smooth lines, almost no mistakes | Every shortcut in the city | Prefers wide streets and keeps his speed |
| Mordor Mike | Fastest hands | Uses nearly all of the car | The main shortcuts | Takes risks, loses focus on the phone |

Halina stays the first rung and stays beatable. She is slow in the corners and brilliant on the
map: she takes the courtyard the player did not know about, and a player who learns it beats her
next time. The courtyards come with step 5 and the rest of the table with step 6a; step 2 built
the "Drives" column's numbers.

A racer should also look as if it is thinking: indicators before a pass or a turn into a
courtyard, brake lights before a corner, a flash of the headlights behind a slow car, a wobble on
a mistake. After the race the result card shows the rival's route against the player's and where
the time went.

### 6.1 Step 6a as built: told apart, and the result card

Step 6a adds nothing to how fast a rival is. It makes what the earlier steps built visible, and
gives each rival the rest of its row in the table above.

**Four traits more per rival** (`ladder.gd`).

| Rival | `dare` | `indicate` (s) | `flash` (s) | `home` |
| --- | --- | --- | --- | --- |
| Pani Halina | 2.5 | 3.0 | never | Powiśle, Śródmieście, the Royal Route |
| Słoik z Radomia | 1.5 | 1.0 | never | nowhere |
| Bulwar Bartek | 1.0 | 1.6 | 3.0 | Powiśle |
| Seba z Pragi | 0.5 | never | 0.8 | Praga |
| Taksiarz Zbyszek | 1.3 | 2.2 | 2.5 | nowhere (he knows every cut anyway) |
| Mordor Mike | 0.7 | 0.7 | 1.2 | Wola |

- **`dare`: nerve in a pass over the centre line** (`traffic.gd` `_pass_start`, `_pass_drive`,
  `_oncoming_clear`). The spare metres of clear oncoming road a pass needs are 10 m times
  `dare` (4 m times it to keep a pass going). A careful rival (`dare` over 1) also counts the
  metres the oncoming car comes that many times over, so Halina wants a gap about twice as long
  as the pass needs. A daring one gets no discount on those metres: the room a pass takes is
  physics, so Seba's nerve is the 5 m he leaves where Halina leaves 25 m, and never a pass that
  cannot be made. `check_race_planner.gd` holds it: a car 160 m off stops Halina's pass and not
  Seba's or Bartek's, and 100 m off it stops everybody's.
  On the bench it moves little, as it should: of 303 races only four of Halina's in traffic
  change (196 passes over the centre line in her 158 races in traffic, 202 without the rule),
  and no other rival's time moves at all against main.
- **`home`: where it knows every way** (`race_cuts.gd` `links`, `area`). Each shortcut and yard
  has its district (`districts.gd`, from its entry). At home a rival knows every cut and every
  yard it fits through and dares, whatever its `cuts` and `yards` shares; away it knows its share
  as before. Halina knew every yard already and three cuts in ten; in Powiśle and Śródmieście she
  knows them all now. No race in the game is in Praga yet, so Seba's home shows first in step 6b.
- **`indicate`, `flash`: its lights** (`race_signals.gd`, below).

**Lights that say what the car does** (`race_signals.gd`, `rivals.gd` `_signal_tick`). Read from
the traffic driver every frame, so a light never says what the car does not do, and nothing here
changes the driving:

- brake lights from a pull of 2 m/s² (lifting off is not braking), held a quarter of a second,
  and while the car stands;
- an indicator before a turn of 26° or more off the street's direction, a shortcut or a yard,
  from `indicate` seconds before the junction and never less than 10 m; and for a lane change or
  a pass out and back. Seba never indicates;
- two flashes of the headlights after `flash` seconds held up behind a slower car (within 14 m,
  3 m/s under its own speed, not already passing), and again after 3.5 s. Halina and Słoik never
  flash;
- the hazard lights for 2.4 s after a wrong turn (Słoik's satnav thinks again; the car also lifts
  off for 0.9 s), and while a rival backs out of a blocked street;
- a wobble of the body on a mistake in a corner, and a slow weave while Mike is on the phone.

The lamps are four small meshes on the rival's car with one shared unshaded material, each drawn
only while it is lit: at most two draw calls more for one car. After the Mac's look (2026-11-13: at the normal camera
a rival is about 10 px long and its lamps were 1 to 2 px) the lamps are 1.3 times bigger and each
has a soft glow of its colour on the road round it (1.5 m behind for the brake lights, 1.1 m at
the corner for an indicator, 1.6 m ahead for the flash), in the lamp's own mesh and material (now
alpha-blended), so a lit lamp is still one draw.

**The result card** (`race_report.gd`, `rivals.gd` `_report_close`, `_report_art`, `hud.gd`
`set_card_art`). While a street race runs the report keeps both cars' ways. At the end it splits
the gap three ways and names the largest, if it is worth a second:

- **the route**: one way was shorter (a shortcut, a yard, a wrong turn), in seconds at the
  winner's pace;
- **the standing**: seconds under walking pace (a queue, a crash, a block);
- **the pace**: the rest, who was quicker on the move.

The card gets one line for that, one with both ways in kilometres, one with what the rival did
(shortcuts, yards, wrong-way hops, wrong turns, mistakes, passes, blocks), and a picture: both
ways over the streets round them, the player's a solid line and the rival's dashed, the start a
dot and the finish chequered. On a phone the card is made wider by the picture; where it would
not fit, the card keeps its width and the words wrap narrower. A race given up has no report.

**Changed the same day (F, 2026-11-13: "detailed info about lose or win is not needed").** The
card keeps its own short lines and the picture of both routes. The report's three lines are no
longer put on it (`rivals.gd` `REPORT_LINES` false); they are still worked out and printed in
the log (`race report: ...`), where tuning reads them.
So after a loss to Halina the player sees the yard she took.

**Found on the way.** The metres to the finish (`RaceCuts.links`) could still hand out a shortcut
that joins a street the rival had found blocked: the time plan never took it, but the distance
shown and the bench's turn-back test were measured through it (720 m short for Halina's blocked
race). The links leave out an exit onto a shut street now.

**The bench** has two marks more (7.3): **Ladder curve** (each rung 3 to 12 % quicker than the
one below, as the geometric mean over the courses every rung has driven on clear roads) and
**Told apart** (every turn of a rival who indicates has its indicator on; the one who never
indicates never does; one who never flashes never does; every wrong turn is followed by the
hazard lights; it also prints the flashes and the passes over the centre line of each). The
ladder's times needed no retuning: SŁOIK 6.9 %, BARTEK 5.7 %, SEBA 7.7 %, ZBYSZEK 5.8 %, MIKE
5.6 % over three courses.

**What it did not do yet.** The pack race, Trzy mosty's field and the police had no lights and
no report (step 6b; the pack has its lights since 6b part 1, 6.2, and no report by F's word). Bartek's block and Seba's contact are the numbers of step 2. A race
difficulty option (easier or harder by the rivals' skill profiles, never by a rival that waits)
is in the backlog for after this step (F, 2026-11-13).

### 6.2 Step 6b part 1 as built: one race session, and the club's pack on it

Step 6b is three pull requests: **6b-1** (this one) the race session, with the ladder races, the
guided first race, Trzy mosty and the night club's pack race on it; **6b-2** the police chasers
on the racers' driver; **6b-3** the crazy drivers.

**Part 1a: the session** (`game/scripts/race_session.gd`, a `RefCounted`). It owns the course,
the racers, the shortcuts, the distances and the plan of every leg, the start, the legs, the
effort, the order, the reroutes, the lights' tick and the end. It has no HUD, no words and no
pay. The statics `Pace`, `arm_racer`, `race_stats`, `pace_tick`, `effort_of`, `own_pace`,
`home_at` and `remaining_from` and the constants `EFFORT_*`, `EASE_FROM`, `EASE_FULL`, `PUSH_*`,
`FINISH_RADIUS`, `HOME_SNAP` and `PLAN_STALE` moved there from `rivals.gd` (2281 lines to about
2030). `rivals.gd` keeps the challenge, the cards, the pay, the talk, the ghost and the player's
checkpoints. The bench's `race()` runs the same session. Proof: the full bench, 304 of 304 old
races identical to main (every field but the wall-clock ones), and the whole-game runs `race`,
`trzy-mosty` and `first10-run` pass. Two switches keep where the game and the bench differed:
`home_circle` (off in Trzy mosty: Seba is home on arriving) and `exact_left` (the bench sums the
legs at full precision).

**Found on the way.** Trzy mosty already drove the plan, the links, the lights and the report
(steps 3 to 6a); it lacked only the shared race object. The pack race had a route in metres and
no plan, so no racing line; its cars had up to 6 % more top speed than the player's car and
corner numbers from before step 4a.

**Part 1b: the pack.** Eight club profiles in `ladder.gd` `CLUB` (six ring cars, Darek, Lena).
All are locals (`cuts` 1, `yards` 1, `narrow` 3, `knows` 0.8, `caution` 0.2, no hops, no wrong
turns), and nobody is over the player's car. Alone on clear roads over the club course (2.9 km
from Plac Defilad's door to meet 2's):

| Racer | share | lat | race_accel | brake | Time alone |
| --- | --- | --- | --- | --- | --- |
| ring 0 | 0.86 | 14.4 | 10.5 | 9 | 161.6 s |
| ring 1 | 0.867 | 14.5 | 11 | 9.5 | 159.0 s |
| ring 2 | 0.875 | 14.7 | 11 | 10 | 157.1 s |
| ring 3 | 0.884 | 14.9 | 11.5 | 11 | 154.3 s |
| ring 4 | 0.893 | 15.0 | 12 | 12 | 151.9 s |
| ring 5 | 0.907 | 15.2 | 12 | 12.5 | 149.5 s |
| Darek | 0.93 | 15.5 | 12.5 | 12 | 146.3 s |
| Lena | 0.98 | 16.0 | 13 | 12.5 | 140.6 s |

They are fitted so that the median racer is within 3 % of the old pack driver's clear-road time
(old 143.7 to 146.3 s from a standing start, median 145.1 s; new median 146.7 s, +1.1 %), and the
field spreads 13.6 %.

**The pack's session.** One session for the race, prepared at the raid (not at the pin). A plan
slice for one racer a frame (`round_robin`). A plan searched toward the racer's road before it
has a Driver (`"from"`: the first frame was 120 ms, now 2 ms). Shortcut tables shared between the
racers of one cuts profile. A racer that is home leaves racer mode. Effort by the time gap, as in
every race. Race lights for the pack, only for the cars in view, built at the race's start and
freed at its end. The better cars come onto the road first (`street_meet.gd` `SCATTER_FROM`,
`GRID`). There is no result report for the pack (F, 2026-11-13: detailed information about a win
or a loss is not needed).

**Two rules in `traffic.gd`**, both only between racers that have plans (a race of one is
unchanged):

- In the look across a junction, another racer that is behind it and still on the street it
  leaves, or less far along the same curve, is not in its way; one ahead on a shortcut's curve
  is (`_race_cross_look`).
- Two racers level in two lanes into one shortcut: the one behind follows the other in
  (`_merge_gap`).

Before them the club's cars drove through each other at the first shortcut (8 to 20 times in the
bench's pack race on clear roads; now 0) and came home out of order (club2 lost 13 s, club4 9 s;
now the order of the profiles).

**Old pack driver against the new one**, the same four bench races (home of 8, old / new; median
s; last s; cars driven through; dead stops; seconds stood, the eight together).

| Race | Home | Median | Last | Driven through | Dead stops | Stood |
| --- | --- | --- | --- | --- | --- | --- |
| Clear, no player | 8 / 8 | 177.8 / 160.3 | 193.2 / 174.5 | 16 / 0 | 2 / 0 | 141 / 9 |
| Clear, average player | 8 / 8 | 176.8 / 173.4 | 193.8 / 186.9 | 16 / 0 | 1 / 0 | 140 / 11 |
| Busy, no player | 7 / 8 | 346.2 / 289.7 | 420 (not home) / 389.8 | 32 / 17 | 18 / 16 | 493 / 256 |
| Busy, average player | 8 / 8 | 357.4 / 348.8 | 380.0 / 363.4 | 13 / 1 | 1 / 1 | 147 / 33 |

**The bench** has a new race kind, `pack`: the club's eight on the course "club", and each racer
alone first ("solo") on clear roads. The quick matrix is 40 races (it was 24 before this step),
the full one 344 (it was 304). Two marks more (7.3): **Pack order** and **Pack in traffic**.
Finishes no longer counts the pack's races in traffic (they have their own mark). The Probe's
pull now divides a speed change by the time since the car was last driven (a pool car out of
sight is driven every other frame).

**Frame cost** (the cloud, software renderer, 120 s, no race on): traffic 1.03 to 1.09 ms (the
trams, which this step does not touch, moved 0.85 to 0.90 in the same pair of runs), rivals 0.10
to 0.11, meet 0.01 to 0.01, scripts 6.03 to 6.04 ms in all, 61 draws in the main pass before and
after. The session's own work in a race is 0.1 ms a frame or less after the start.

**Known and left** (BACKLOG). In Busy traffic a club racer far from the player still pays a
large out-of-sight delay (`AWAY_*`, fitted on narrower streets: the wide-street case of step
4b's notes; 629 s for the eight together with nobody near, 1,349 s with the average player),
so the pack takes about twice its clear-road time there, and with nobody near the eight still
drive through 17 cars in Marszałkowska's queue (the old driver: 32). The
session's worst frame is the one plan slice before the start (0.9 ms median, 3.6 to 5 ms at
worst on the cloud machine; 19 ms seen once in a whole-game run and not traced: the phone is the
question). The police chasers and the crazy drivers are 6b-2 and 6b-3.

`check_street_meet.gd` follows: the handed-over racer has its CLUB profile's share, `race_accel`,
`lat`, `brake`, block, the car's top, `CLUB_PACE`, a plan and a shortcut table (before: the old
`RACE_ACCEL` and `RACE_LAT`); every racer has its lights in the race; and after meet 2 the
session and the lights are gone.

### 6.3 Step 6b part 2 as built: police chasers on the racers' driver

A police car in a chase (`police_unit.gd` `pursue`) drives the racers' driver: a plan by its own
seconds toward the player, the racing line, a tight curve as the arc a car can turn, honest
braking into turns, and a new way after `turned_back` or `hop_refused`. Before it was a rail
racer: a route by the metres once a second, no plan, no line, curves as they are, with
`CHASE_RACE_ACCEL` 6 and `CHASE_LAT` 6.5 from before step 4a's grip. It measured 27 to 42 m/s²
sideways, which no real car does; it measures 8.6 to 15.2 now.

**The chase's own object** (`game/scripts/police/chase_route.gd`, a `RefCounted`).
- The replan rule moved out of `police.gd` and is the same: a route once `REPLAN` 1 s for each
  chaser, one chaser a frame; the goal is the end of the player's street when that is within
  `GOAL_NEAR` 400 m of the car, else the nearest junction; the search is bounded at `MAX_COST`
  800 m.
- The chase's `RaceSession`: a chaser joins when it pursues (`join`, from `police_unit.gd`
  `arm_chase`) and leaves when it stops (`leave`).
- Only a new goal junction remakes anything (`RaceSession.retarget`: one leg, the distances and
  plans dropped and made anew). The chaser routed now is sent at once and the others one a frame
  after (`_resend`). Plan slices go one chaser a frame (`round_robin`), never in a frame that
  remade a goal.
- The bench's chase races drive the same object, so no copy of the rule exists.
- The search, the escort, the blockers and the roadblocks still drive the old way (no plan).

**The session's additions** (`race_session.gd`): `max_cost` (distances bounded; `INF` for every
race as before), `remove(r)`, `retarget(junction, most, send)` and `resend(r)`; `_reroute` honours
`max_cost`. A chaser has no effort by the gap (its pace is its own: its top is `police.chase_top()`,
0.8 of the player's car, by `v_cap`), no race lights (it has the light bar) and no finish circle.

**The profile** (`ladder.gd` `POLICE`): share 1.0, `race_accel` 7, `brake` 6, `lat` 12, knows
0.6, caution 0.5, dare 1.5, narrow 4.5, cuts 0, yards 0, hops 0, wrong 0, mistake 0, block 0, no
phone. The first try was 10 / 9 / 12.5 (the old numbers scaled as the club's were), and it was
too much: the line made the chaser quicker through corners, so the fast player no longer escaped
on the Powiśle course. The pull and the brakes came down.

**Six changes in `traffic.gd`**, all for a chaser:
- `_choose_way`: a chaser uses its plan only once the plan knows its street (`plan.step(e, 0)`);
  before that it goes by the metres.
- The tight-curve arc, for a chaser with a plan.
- `lined()` no longer shuts chasers out.
- In `_line_speeds` a chaser's line ends at `_chase_end_speed` (new): the slowest way on from the
  goal junction at its grip, because the player's next turn is not known (`race_line.gd`
  `end_speed`).
- The look at the player is 4 m wide as before, or anywhere on the chaser's own carriageway when
  it is on its line (`_on_carriageway`): a line may pick another lane than the player's, and a
  chaser never draws alongside to pass.
- Everything else about `d.chase` is as it was: it keeps `CHASE_GAP` behind, never passes or
  rams, and goes slowly through a red with the siren.

**The bench** has a new race kind, `chase`: the test player (average, fast) on three courses
(avenue: the spawn to the Palace; powisle; yard, where the player takes a shortcut), with one or
two chasers starting 30 and 60 m behind, armed and routed by the game's own code. A race ends at
45 s or at the escape (100 m from every chaser). Every chase race runs twice, `old` (no plan, the
driver before) and `new`, in the same bench: 72 chase rows. The quick matrix is 41 races (it was
40), the full one 416 (it was 344). The old chase rows are kept out of the existing marks, and
chasers are not finishers. The situation "busy" is the bench's `heavy`. Two marks more (7.3):
**Chase keeps off** (36 chasers, 0 rams, 0 in front) and **Chase balance** (medians 0.09 to 0.20
of the limit, worst 1.43).

**Old chase driver against the new**, clear roads, first chaser (old / new):

| Course, player | Gap at 10 s | at 20 s | at 30 s | at 45 s | Escape |
| --- | --- | --- | --- | --- | --- |
| Avenue, average | 27 / 30 m | 33 / 34 m | 35 / 33 m | 37 / 34 m | - |
| Avenue, fast | | | | | 13.9 / 13.4 s |
| Powiśle, average | 31 / 31 m | 29 / 28 m | 27 / 29 m | 45 / 33 m | - |
| Powiśle, fast | | | | | 28.0 / 27.3 s |
| Yard, average | | | | | 17.8 / 18.0 s |
| Yard, fast | | | | | 14.5 / 15.0 s |

The old second chaser on the avenue got lost (171 and 316 m behind); the new one stays 35 to 73 m
behind. Heavy traffic is noisy for both drivers.

**Proof that nothing else moved.** The 344 races of the bench before are identical to main's
(only the session's own wall-clock fields differ). The other marks are as on main. Dead stops
went 80 to 84, four of them among the new chasers (Honest car is a known fail of the rebuild).

**Frame cost.** The chase's own script work a frame in the bench: worst 1.1 to 2.8 ms with three
bench jobs at once and up to 3.4 ms alone (the old driver 0.47 ms), median about 0.01 ms. The
frame bench (the cloud, no chase in it): traffic 1.02 to 0.95 ms, police 0.11 to 0.11, rivals
0.10 to 0.09, draw calls 106 to 106 (58 in the main pass). Only the phone can show the chase's
worst frame and how a chase feels: braking into turns, keeping off, the escapes.

**Known and left** (BACKLOG). Shortcuts for the police (a patrol keeps to the roads for now); the
search phase, the escort and the blockers still on the old driver; the crazy drivers are 6b-3.

### 6.4 Step 6b part 3 as built: crazy drivers on fares

The crazy drivers (taxi, courier, Pasatini; crazy-drivers.md) drive the racers' driver: a plan by
their own seconds to a fare, the racing line, a tight curve as the arc a car can turn, honest
braking into turns, and a new way after `turned_back` or `hop_refused`. Before they wandered in
racer mode with no route: corners as the junction curve is, no plan, no line. They measured 27 to
64 m/s² sideways, which no real car does; they measure 9 to 15.5 now. Step 6b is done with this:
every race mode drives the new driver (the ladder, the first race, Trzy mosty, the pack race,
the police chasers, the crazy drivers).

**The fares' own object** (`game/scripts/crazy_route.gd`, a `RefCounted`), owned and ticked every
frame by `crazy_drivers.gd` (its 4 Hz voice tick is unchanged), because the fares are the crazies'
own.
- A **fare** is a junction 600 to 1500 m away, roughly ahead of the car, in the strongly connected
  part of the map and inside the band's area (outside the edge roadworks' band). It is picked by
  the fares' own generator (`FARE_SEED` 2031), so no other car's draw moves. The next fare is
  picked when less than 150 m are left; a fare not reached in 240 s, or unreachable, is dropped.
  The distances are bounded at 2000 m (`MAX_COST`).
- One `RaceSession` per crazy, since each has its own goal: it joins on traffic.gd's new
  `crazy_spawned` signal and leaves on `crazy_released`. Each frame does one of: a fare search,
  one send, or one plan slice of 40 states (`SLICE`), never two of them.
- A crazy with no ride (the bench's `old`, a run without that node) wanders as before.
- The bench's `crazy` races drive the same object, so no copy of the rule exists.

**The profiles** (`ladder.gd` `CRAZY`, taxi / courier / Pasatini): share 1.0, `race_accel`
3.2 / 3.0 / 4.0, `brake` 5.6, `lat` 10 / 9 / 12, knows 0.8, caution 0.1 / 0.1 / 0, `dare` 0.6 /
0.6 / 0.5 (bold), cuts 0.6 / 0.8 / 1.0, yards 0.5 / 0.8 / 1.0, narrow 3, hops 0 / 0 / 0.3,
`mistake` 0 / 0 / 0.15, `block` 0.5 / 0.5 / 0.75, `phone` true for the taxi. The top and the cap
over the limit stay `CRAZY_TOP` and `CRAZY_OVER` (traffic.gd), applied after the plan's speed.
The starting values passed the fit; none moved. Their character is kept: over the limit, fresh
reds, blocks and tight cut-ins, the Pasatini running wide near the player, never slipping through
a queue, yielding to crossing cars, the voice's cut-in counts.

**Changes in `traffic.gd`**:
- Signals `crazy_spawned` / `crazy_released`, the spawn statistics in `_crazy_stats`, and
  `add_crazy` for the bench.
- `_choose_way`'s plan gate and the arc gate include a crazy with a plan; the racers' corner and
  mistake branch skips crazies; the crazy corner rule uses the arc and skips hairpins (with no
  plan the arc is the curve, as before).
- `lined` lets crazies in; a crazy's line ends at its fare at the slowest way-on speed, as a
  chaser's does; the out-of-sight delay stays off for crazies.

**The planner's cache** (`race_planner.gd`): a per-planner cache of link curves, bend speeds and
drive times (`link_curve`, `link_bend`, `link_time`, `warm_link`); results are unchanged.
`crazy_route.gd` fills it for every link at setup (the city's load: about 110 ms for the three
kinds on the cloud machine), else a step at a time in frames that have spent less than 1 ms.
Before, the first meeting of a long yard link cost 1.2 to 2.7 ms in one frame; now the worst
planner step is 0.13 ms.

**The bench** has a new race kind, `crazy`: one crazy of each kind, 180 s, three spawns (avenue,
powisle, tamka), clear and heavy, with and without the average test player; every race runs twice,
`old` and `new`: 72 rows. The full matrix is 488 races (it was 416); the quick one gains one (the
taxi, clear, with the player). Two marks more (7.3): **Crazy pace** and **Crazy stays crazy**.

**Old crazy driver against the new**, clear roads, the median over the three spawns:

| Kind | Mean speed new / old | Cut-ins near the player, new against old |
| --- | --- | --- |
| Taxi | x1.07 | +0 |
| Courier | x1.04 | +1 |
| Pasatini | x1.06 | +0 |

Single races spread x0.8 to x1.8 (a fare against a wander). With the test player, the cut-ins
near it were 11 / 16 / 7 for the three kinds. In Busy traffic the new crazies cut in 27 times
against the old ones' 7, and the bench's player overlaps them 9 times against 1. Traced: the
bench's player (no brakes for a car ahead) runs into a crazy that cut in ahead of it; the crazy
is never alongside or behind. No driving change. In the game the player's car is solid: the
phone shows how that feels.

**Proof that nothing else moved.** The 416 old races are identical to main's (only the wall-clock
fields differ). Verify passes. No crawl went from 2.3 to 3.0 s, at its limit; the 3.0 s is an
old-driver crazy row on Powiśle.

**Frame cost.** The crazies' script work a frame, single job: median 2.1 ms in the frames that
work, 0.009 ms over all frames (old 0.002), worst 3.3 ms (3 of 36 rows over 3 ms; the brief's gate
was 3). What is left is one send building its racing line in one go (as every racer's send does)
and the 2000 m search on the frame a fare is picked; splitting either changes the driving. The
frame bench (the cloud): traffic 0.91 to 0.93 ms, a new row "crazy drivers" 0.10 ms, draw
calls 106 to 106. Only the phone can show the worst frame, the load-time cost and the cut-ins'
feel.

**Known and left** (BACKLOG). The planner does not know `CRAZY_OVER` (it plans by the limit, the
car then goes over it); the worst frame (3.3 ms) on the phone; both drivers (the chasers' and the
crazies') stop dead at Tamka and Most Świętokrzyski, where a red follows a junction curve.

## 7. How we test it: the race bench

Racing has its own test bench, and no step of the rebuild merges without its numbers.

### 7.1 What it is

`game/tools/race_bench.gd` runs one rival's race from start to finish on the committed map's lane
graph (`game/map/centrum.json`) with the real `traffic.gd` and the game's own race code
(`rivals.gd`'s static core: `arm_racer`, `pace_tick`, `first_start_step`, `remaining_from`,
`finish_node`, `lane_behind`), but without the city, the car, the HUD or a renderer. A clear race
takes 0.2 s to run and a race in Busy traffic 3 to 5 s, and the same race comes out the same every
time. Each race gets a fresh traffic system with its own seeds and the lights' clock at zero, the
grid as `rivals.gd` `put_ahead` lays it (the rival 14 m in front of the car; in the first race
12 m behind it) and the 5.6 s of challenge line and countdown before the start. A rival's own dice
are seeded from the race's name, so its wrong turn and its mistakes are the same whoever the test
player is.

Since step 3 a race has the rival's plan as the game makes it (`race_planner.gd`): made at the
start for the traffic the race has, told of a blocked street by the driver (`turned_back`), with
the metres left counted again as `rivals.gd` does (`traffic.reroute`). The finish is the game's:
the plan, the metres and both cars' arrival go by the finish's circle and the roads through it
(`RacePlanner.ends`, `Rivals.home_at`). A spec's `no_plan` runs a
race by metres as before (the traffic tool needs the same streets with and without the town's
cars), and `view` holds the view away from the race, so the rival is out of the town's cars all
the way.

The player is a **test player**: a ghost driver on the lanes, as the game's `--autopilot`. The
view (and so the town's cars, which exist only round it, and what counts as "seen") follows the
test player; with no player it follows the rival.

| Test player | What it does | What it is for |
| --- | --- | --- |
| `none` | nobody | the rival's own pace: the yardstick for the others |
| `stopped` | never leaves the line | a player who waits to watch her |
| `slow` | `--ghost-pace 0.5` | a careful new player |
| `average` | `--ghost-pace 1.8` | the autopilot's normal player |
| `fast` | `--ghost-pace=racer` | a skilled player, flat out |
| `follower` | sits 15 m behind the rival whatever the rival does (in the first race it rolls off the line at 8 m/s until she is past) | F in the screenshots: the player on her tail |

| Situation | Set-up | The racer must |
| --- | --- | --- |
| `clear` | no traffic | drive its own best time and pick the fastest route |
| `heavy` | Settings → Traffic: Busy. In the full matrix every race in traffic is run in three draws of the town's cars (its own, and a spec's `seed` 3 and 4) | pass slower cars and not drive through them |
| `low` | Settings → Traffic: Low, the whole game's own level (full matrix, three draws) | the same, with room to do it in |
| `blocked` | clear roads; parked cars across every lane, both ways, of a street on the rival's own route near 45 % of the way (one with another way round at most 1.6 times as long) | take another way |
| `crash` | clear roads; a wreck across its lanes near 35 % of the way (where there is a lane to go round in) and a knock from the side at 60 % (`traffic.gd`'s `DAZE` and `SHOVE_SLIDE`, 60 % of its speed lost) | go round, come back from the knock, finish |

The prototype race is F's: Powiśle to Plac Trzech Krzyży, from two starts. `tamka` (200, -400) is
where F raced; there is one obvious way. `leszczynska` (300, -790) in north Powiśle has three
useful routes within 15 s of each other, each forced through a point or two for the comparison:
`dobra` (Zajęcza, Dobra, Czerwonego Krzyża, Kruczkowskiego), `topiel` (Zajęcza, Topiel,
Kruczkowskiego) and `solec` (Jaracza, Solec, Ludna).

Three more courses since step 4b, each measured before with a scratch spec only: `marszalkowska`
to the Palace (995 m of wide street, two and three lanes each way, and a finish with a road
through its circle), `spawn` to the Palace (the whole game's `--race=0`), and `poniatowski`: the
final's last stretch, 557 m from the middle of Most Poniatowskiego to Trzy mosty's finish, with
the final's own racer (a spec's tuning `final`).

### 7.2 Running it

```zsh
tools/race_bench.sh                    # the full matrix: 488 races since step 6b part 3, about 30 minutes with --jobs=3
tools/race_bench.sh --jobs=4           # ... in four parts side by side, judged as one run: 4 minutes on four cores
tools/race_bench.sh --quick            # the quick matrix: 42 races, 30 s (verify step `racebench`, in CI)
tools/race_bench.sh --only=tamka/heavy/none --trace   # some races, with what the rival does once a second
tools/race_bench.sh --out=before       # on main: build/race_bench/before.json ...
tools/race_bench.sh --against=build/race_bench/before.json   # ... then on the branch, both runs side by side
tools/race_bench.sh --write            # record both matrices' marks (when a change moves one on purpose)
tools/verify.sh --only=raceplanner     # the planner's own check: the table, the choices, the finish, eleven races; 8 s (in CI)
tools/race_traffic.sh                  # what the town's traffic costs a racer: 300 races and the fit, 8 minutes on four cores
```

In a clone Godot has never opened, the script imports the project first (the game's scripts do
not load without it). The check itself fails when a race did not run, so a broken set-up cannot
print OK.

The quick matrix is Pani Halina from Tamka: a ladder race on clear roads against all six test
players, in Busy traffic against four, the blocked street and the crash; the guided first race
against four; the free choice from Leszczyńska and its three forced routes; one race twice. The
full matrix adds every test player to both tunings, both starts under every situation, two more
draws of the traffic, the forced routes in traffic, the other five rivals on clear roads and in
traffic, and the guided first race from Marszałkowska to the Palace (a finish with a road
through its circle) on clear roads and in Busy traffic, alone and with the average test player.

Since step 4b (2026-11-12) the full matrix also has: every rival alone on clear roads from
Leszczyńska and from Marszałkowska to the Palace (the ladder is judged on each course); Seba
from Marszałkowska to the Palace in Busy traffic alone, with a player who never leaves the line
and with the average one (the wide street, below); Seba from the map's spawn to the Palace on
clear roads and in Low traffic; Low traffic on the prototype race and from Leszczyńska; the
final's last stretch on clear roads and in Low traffic; and every race in traffic twice more,
in two other draws of the town's cars. That is 272 races: 75 without the town's cars, 140 in
Busy traffic and 57 in Low.

`game/tools/check_race_planner.gd` (verify step `raceplanner`) holds what the marks cannot say
about the planner: the traffic delay's formula and who counts how much of it; the search in
slices against the search at once; a street shut once and the way round it; a wrong turn that
costs 4 to 15 s and is never the way back; a hairpin at a car's own turning speed; the finish
(the roads through a circle and their level, the plan and the metres to the line, a car home at
the line in the furthest lane and not short of it, past it, beside the road or on another level,
Trzy mosty's finish); and eleven races: the plan's clock against the race as driven, backing out
of a walled one-way street, a U-turn in a walled two-way street, the turn back behind the
player's stopped car, the delay paid out of the town's cars, the lane held past a slow player,
and the first race to the Palace on clear roads and in Low traffic. Thirty-three deliberate
breaks of the code were each caught by it before it joined verify.

`tools/race_traffic.sh` is not a check. It measures the planner's traffic delay
([5.1](#51-step-3-as-built-the-plan-the-way-round-the-towns-traffic)): `game/tools/race_traffic.gd`
drives the races and writes a line a street, `tools/race_traffic.py` fits the delay's numbers and
says how well the ones in `traffic.gd` still give a race's time. Run it when the way a racer
meets the town's cars changes, and move the constants when the fit has.

A race prints one line (its id is `rival/tuning/start/situation/player`), then what went wrong:

```
halina/ladder/tamka/heavy/none   130.8 s x1.00   47 km/h (top  73) · crawl 5.7 s (longest 1.2) · behind 1.1 s · stood 10.5 s · passed 13 · effort x1.00-1.00 · Tamka > Solec > ... · 32 cars, 3.2 s
    THROUGH 5 cars (38.9 s a car on Leona Kruczkowskiego, ...) · 3 slips (3 seen) · touched 4 cars · stopped dead 5 times (35.5 s from 27 km/h on Leona Kruczkowskiego, ...) · sideways 37 m/s²: 72 km/h through 42° in 8 m on Książęca (359, 433) at 83.5 s
```

`x1.00` is the time against the same situation with no player, `effort` the range of the rival's
effort (section 6), the last two numbers the town's cars round the rival and the seconds the race
took to run. A fault comes with its place, so it can be looked at in the game (`--at=357,429`). With
Godot's own `--verbose` every car driven through is printed with both cars' states, and every
wait of more than 4 s behind a slower car with a free lane beside it.

The json keeps every number of every race. Since step 4a also `head_ons` (of the cars driven
through, those that came the other way) and what the traffic's step cost: `step_usec` (its
mean), `step_most_usec` and `step_most_at` (its slowest frame and when), `steps_slow` (the
frames over 1 ms: on clear roads they are the stretches of line built; in Busy traffic the
count moves with the machine's own load).

`--jobs=N` runs every Nth race in its own process and judges the parts together. A race does not
depend on the races before it, so the races come out the same as in one go (checked: all 110
races of step 4a's matrix, every number but the timings). The timings (`step_usec`, `wall_ms`)
are only good from a run with nothing beside it.

### 7.3 The pass marks

`race_bench.gd` `judge` turns a set of races into twenty-two marks. The limits are constants at the
top of that file; a change that moves one says why in its PR.

| Mark | Passes when | Step |
| --- | --- | --- |
| **Finishes** | every race reaches the finish within 420 s | 4b |
| **Independence** | with a test player the rival's time (from the moment it is let go) is within 15 % of its time with no player on the same roads, faster or slower, and a race it finishes alone it finishes with any player. Since step 4b the 15 % is held for each race on clear roads by itself (the same race on any machine), and among the town's cars for a pair's seconds over all the draws it was run in (with the player, against alone in the same draws), with no single race in traffic more than 40 % off; a pair run in fewer than three draws is held to the 40 % only, because one draw of the town's cars is no measure of a pair (`INDEPENDENCE_DRAWS`). In traffic too since step 3: the town's cars are where the view is, and a rival beyond them pays the delay they would have cost it (before, only slower counted there, because a player left behind meant empty streets round the rival). A race the rival never finishes because the player's own stopped car stood in front of it with no lane to pass in, for more than half of the race, is not judged here: that is a block and not a pace that follows the player's (Finishes counts it, and step 4b's driver has to get round) | 2 |
| **No crawl** | never more than 3 s in a row under half of the road's racing speed on a free straight road: nobody within 30 m in front, the next 40 m of its own way bending less than 0.3 rad, not held at the line, not knocked, not on a junction's curve. Pulling away after the game stopped the car dead is not a crawl (until it is back at half of the road's speed, 4 s at most): Honest car counts every dead stop, and since step 4a the two are not one fault counted twice. Since step 4b "in front" is by the street's direction, not the car's nose (a car that stopped half way into the next lane stands askew beside its queue), a road is not free while the rival gives way to a car that crosses it at a junction within 30 m, and a car within 6 m ahead in the next lane's width is in front too (the head of a queue turning across a rival that passes it) | 2 |
| **Passes traffic** | among the town's cars (Busy, and since step 4b Low) never more than 4 s behind the same slower car (under 0.7 of the road's racing speed, within 12 m) while a lane beside it is free: another lane of its road with no slow car from 6 m behind to 30 m ahead, or, for a rival in the lane by the centre line, the oncoming lane with no car for 80 m (step 4b: from another lane there is a lane of cars between it and the oncoming one) | 4b |
| **No ghosting** | never inside another car's box (traffic.gd's own test; the town's cars, parked ones and the player's) for 0.25 s or more. Less is a touch, the bump of a collision. Since step 4b a car on a viaduct and a car on the street under it are not in each other's box away from a junction (the bench's map is flat: Aleje Jerozolimskie over Leona Kruczkowskiego was one place) | 4b |
| **Re-routes** | with its street walled off it finishes, drives through no car, and takes no longer than its clear time stretched to the way of a driver who finds out at the wall (to the wall, back to the junction behind, round from there), times 1.2, plus 8 s | 3 |
| **Recovers** | never moved by the game in view (pushed through a car, or put somewhere else), and with the wreck and the knock it finishes, drives through no car and loses at most 12 s against the same race without them | 4b |
| **Honest car** | never over the player's car's top speed (108 km/h), pull (15 m/s²), sideways grip (19 m/s², measured as v² x turn / 8 m over every 8 m of its way, but for the 8 m in which the game stopped it dead: its heading swings as it stands) or brakes (30 m/s²: a harder stop is the game stopping the car, not the car) | 4a, 4b |
| **Route sense** | its own choice of route is at most 5 % slower than the best of the forced routes (on clear roads; in the full matrix in traffic too) | 3 |
| **Skill ladder** | flat out on clear roads with no player, each rival up the ladder is as fast as the one below (1 % slack) and the top rival at least 10 % faster than the first. Full matrix only | 2 |
| **Ladder curve** | on clear roads with no player, each rung is 3 to 12 % quicker than the one below, as the geometric mean over the courses all six have driven: no rung is a wall and no two are the same race. Full matrix only | 6a |
| **Told apart** | a rival's lights are its own: one who indicates has its indicator on into every turn it makes, one who never does never has; one who never flashes its headlights never does; every wrong turn is followed by the hazard lights. It also prints each rival's flashes and passes over the centre line, read and not judged | 6a |
| **Yard links** | on the yard course on clear roads, a rival who knows every yard takes a race link and one who knows none takes none. Full matrix only | 5 |
| **Wrong-way hops** | on the hop course without the town's cars: a rival who dares takes the hop on clear roads, refuses it with a car parked on the street and still finishes; one who does not dare never takes one | 5b |
| **Wrong-way hops in traffic** | in every race in traffic: no car of the town's on a street while a racer hops it (or turning into it), none driven through there, and no hop by a rival who does not dare. Full matrix only | 5b |
| **Pack order** | the club's eight on the course "club" on clear roads with no player come home in the order of their own pace (each racer alone first: "solo"); neighbours less than 1.5 % apart may swap; all eight are home. Quick and full matrix | 6b-1 |
| **Pack in traffic** | in the pack's races in Busy traffic every club racer is home within 420 s. Full matrix only | 6b-1 |
| **Chase keeps off** | in the bench's `chase` races (the new driver; the old ones are kept out) no chaser overlaps the player's car or is in front of it on its street: 36 chasers, 0 rams, 0 in front. Quick and full matrix | 6b-2 |
| **Chase balance** | on clear roads the new driver against the old: the average player's gap to the first chaser at 20 and 30 s within 12 m, the fast player's escape time within 15 %; a course may go to twice that. Full matrix only | 6b-2 |
| **Crazy pace** | on clear roads the new crazy driver against the old, the median over the spawns: mean speed x1.0 to x1.1 of the old driver's, and cut-ins near the player not fewer than the old driver's minus one: taxi x1.07 +0 cut-ins, courier x1.04 +1, Pasatini x1.06 +0. Full matrix only | 6b-3 |
| **Crazy stays crazy** | with a player every kind cuts in or blocks near it at least once; every new crazy on clear roads reaches a fare; in traffic each kind does at least one: cut-ins near the player 11 / 16 / 7. Quick and full matrix | 6b-3 |
| **Same race twice** | a repeated race gives the same time, streets and metres | 1 |

The probe that measures a race (`race_bench.gd` `Probe`) reads what a spectator could see: where
the car is, how fast, which way it points, the cars round it. So it measures the next driver the
same way as this one. Only the "moved by the game" count looks inside today's traffic.gd (its
`squeeze`).

### 7.4 The marks today

Recorded in `game/data/race_bench.json`, for each matrix. `check_race_bench.gd` holds every run
against them:

- a mark recorded **pass** that fails is a problem (exit 1, a FAIL in verify): the change made
  the racers worse;
- a mark recorded **fail** that passes prints `racebench: WARN ...` (a WARN in verify) until it
  is recorded with `tools/race_bench.sh --write` in the same PR;
- a mark recorded **fail** that fails is the known state of the rebuild, listed in the OK line;
- a mark recorded **unsteady** is shown and not held either way. It is set by hand, for a mark
  that passes or fails with the draw of the town's cars, and `--write` leaves it alone.

`--write` records what one run on one machine saw. A mark that counts races in traffic is
recorded pass only when it also passes on the other machine (the Mac's run of a race in traffic
is another draw of the town's cars than the cloud's, 7.5) and in other draws (a race's `seed`).
Step 4a learned this with Independence, below, and since step 4b the check does it itself:

- the full matrix runs every race in traffic in three draws, and the marks that count them are
  read over all three (Independence by pairs over the draws, 7.3; the contact counts are also
  printed draw by draw, so a change is told from the draw's own spread);
- a mark that counts races in traffic and passes for the first time is recorded
  `once:Linux` (or `once:macOS`): passed on one machine, not held yet. `--write` on the other
  machine turns it into `pass`; a fail on either puts it back to `fail`.

So each step turns marks from fail to pass on purpose, and nothing slips back.

**The baseline for step 4b** (2026-11-12): step 4a's driver on the new matrix of 272 races.
Nothing in the game changed; these are the numbers step 4b's driver is held against.

| Mark | Full matrix (272 races), step 4a's driver |
| --- | --- |
| Finishes | **fail**: 268 of 271. The three are one race in its three draws: the first race from Tamka with a player who never moves, in Busy traffic |
| Independence | **fail**, and no longer unsteady: 12 % at the most on clear roads; in traffic 3 of 45 pairs are over 15 % over their draws, and each is a known fault. The first race from Tamka with the average player, +52 % (−9, −9 and +169 % in its draws: the turn back behind a car that only waits). Seba on Marszałkowska with a player who never leaves the line, +20 % (+35, +23, +6 %: the delay he pays out of the town's cars, fitted on narrower streets). The first race from Leszczyńska with a player who never moves, +17 % (+9, +35, +6 %: the turn back again). Every other pair is within 11 % and the pairs' mean is 6 % |
| No crawl | pass: 2.3 s |
| Passes traffic | **fail**: 6.5 s; more than 4 s in 21 of the 196 races in traffic (9 of 139 in Busy, 12 of 57 in Low) |
| No ghosting | **fail**: 473 cars driven through (437 in Busy traffic, 112 of them head-on; 36 in Low); in Busy traffic 139, 136 and 147 by draw |
| Re-routes | pass: 9 of 9 |
| Recovers | **fail**: moved by the game in view 170 times (54, 48 and 44 by draw in Busy traffic); 9 of 9 crashes recovered |
| Honest car | **fail**: stopped dead by the game 382 times (116, 100 and 114 by draw). Sideways 23.6 m/s² against the car's 19: with more draws the slide of a pass is over the limit in 12 races (Słoik pulling out at 89 km/h on Solec), as 5.2 said it could be |
| Route sense | pass |
| Skill ladder | pass on all three courses: from Leszczyńska 123.7, 111.8, 108.8, 100.4, 94.4 and 88.8 s; from Marszałkowska to the Palace 59.6, 59.2, 52.7, 48.6, 45.9 and 43.4 s |
| Same race twice | pass |

The new courses with step 4a's driver: Seba from the spawn to the Palace 41.6 s on clear roads
and 42.6 to 47.3 s in Low traffic alone; the final's last stretch 20.2 s on clear roads and
33.8 to 39.8 s in Low traffic (the bridge's lanes behind the town's cars: step 4b's pass).

After step 4a (2026-11-12), on step 4a's matrix of 111 races, with step 3's number in brackets
where it moved:

| Mark | Quick matrix (21 races, Pani Halina) | Full matrix (111 races, all six rivals) |
| --- | --- | --- |
| Finishes | pass since step 3: 20 of 20 | **fail**: 109 of 110, the first race from Tamka with a player who never moves, in Busy traffic: see below |
| Independence | pass since step 2: her time moves up to 11 % with the player, on the Mac too | **unsteady**: 13 % in the cloud's run (16 %), 22 % in the Mac's (17 %), and 25 to 170 % in three other draws of the town's cars (18 to 166 %): see below |
| No crawl | pass since step 2: 1.7 s in a row | pass since step 2: 2.3 s (2.7 s) |
| Passes traffic | **unsteady**: 1.5 s in this draw of the traffic (8.2 s) | **fail**: 6.2 s (8.2 s); more than 4 s in 2 of the 48 races in Busy traffic (11) |
| No ghosting | **fail**: drove through 17 cars (5) | **fail**: 150 cars, 80 s inside one in all (152, 114 s) |
| Re-routes | pass since step 3: 1 of 1 | pass since step 3: 9 of 9 |
| Recovers | **fail**: moved by the game in view 6 times (once); the crash itself recovered | **fail**: 60 times (79); 9 of 9 crashes recovered |
| Honest car | **fail**: stopped dead by the game 16 times (5). Sideways 18.2 m/s² against the car's 19 (49) | **fail**: stopped dead 130 times (140). Sideways 18.4 m/s² (77.6): no race is over the car's 19 (109 of the 110 were) |
| Route sense | pass: her own choice 123.7 s, the best forced route 124.1 s | pass: in traffic too |
| Skill ladder | not judged (one rival) | pass since step 2: 99.6, 88.6, 87.0, 80.2, 75.7 and 71.6 s up the ladder, the top rival 39 % faster than the first |
| Same race twice | pass | pass |

What step 4a turned, and what it left open ([5.2](#52-step-4a-as-built-the-racing-line-and-a-speed-for-every-metre)
has each fault traced):

- **Honest car's grip.** No race is over the sideways limit of the player's car: the line's
  speeds are the mark's own measure. The mark stays recorded fail for the dead stops (a car
  across a junction), and the one place near the limit is a pass's sideways slide: step 4b.
- **Independence on the full matrix is recorded unsteady**, by hand, and is not held until
  step 4b makes it steady. The cloud's run reads 13 % and passes, and `--write` recorded that
  at first. The Mac's run of the same matrix reads 22 % and fails (16 and 17 % at step 3). On
  clear roads the two machines run the same races (the ladder's six times agree to the tenth
  of a second, and Independence there is 12.5 % on both, 13.2 % at step 3: the first race from
  Leszczyńska with the slow test player). With the town's cars they do not, so the Mac's run
  of a race in traffic is another draw than the cloud's (the likely cause, not traced: the two
  processors round a sum differently in its last digit, one car chooses otherwise and the rest
  follows). The mark is the worst of 32 such races, each run once. Three more draws in the
  cloud (a race's `seed`) say what that is worth: 35, 170 and 25 % with this step, 166, 18 and
  23 % at step 3, while a race's time with a player is 5 to 12 % from its time alone on
  average in every one of them, with this step and at step 3 alike. So the mark fails in four
  of the five draws measured with this step and in all five at step 3: the pass was the draw.
  The large numbers are one fault, which step 3 built and step 4b has to mend: a rival that
  stands 3 s behind the player's stopped car with no lane to pass in takes the street for
  blocked (`BOX_WAIT`), also when the player has only stopped for a moment in the traffic. In
  one draw the average test player stands still for five seconds on Książęca, 171 m before the
  finish; Pani Halina, 6 m behind it, makes a U-turn after three of them and goes 3 km round
  by Rozbrat and Aleje Ujazdowskie, home in 373 s where the player is home in 155 s (138 s
  alone). The matrix's own draw shows the mild case of
  it: the first race from Leszczyńska in Busy traffic with a player who never moves still
  makes its U-turn and goes round by Dobra, in 204 s as before, and her time alone there is
  187 s where it was 177 s, because alone she now goes by Dobra too (the plan's choice in Busy
  traffic, 5.2).
- **Passes traffic** is better and not yet a pass: with the oncoming lane a pass uses read
  right, a wait of more than 4 s is rare. The mark turns with the real overtake.
- **No ghosting, Recovers.** Level on the full matrix, with a third less time spent inside
  another car; up on the quick matrix's four races, a draw. Both are the old driver's: step 4b.

Step 3's own account, with its numbers:

The full matrix has four races more than step 2's: the first race to the Palace (below). On
step 2's 107 races alone step 3 gives 105 of 106 finished, 148 cars driven through, 78 moves by
the game and 132 dead stops.

What step 3 turned, and what it left open:

- **Re-routes.** All nine walled streets are taken another way and no car is driven through.
  Halina from Tamka with Leona Kruczkowskiego shut: 163 s, by backing out to the junction behind
  and round (190 s allowed for a driver who finds out at the wall; before, 104 s straight through
  the wall).
- **Finishes.** The first race from Tamka with a player who never leaves the line: on clear roads
  she now waits her 12 s, stands 5 s behind the player's car, backs out of Tamka and comes home
  another way in 132 s. In Busy traffic the town's cars queue behind her and she has no room to
  back out: the one race of the full matrix that does not finish, for step 4b's driver, who goes
  round where the player's car could.
- **The finish.** The guided first race from Marszałkowska to the Palace, on clear roads and in
  Busy traffic, alone and with the average test player: 65.5, 69.0, 88.7 and 80.5 s, each home
  at the finish's line after the route's 995 m. Step 2's driver took 65.5, 68.1, 117.9 and
  100.8 s: alone in Busy traffic she passed the Palace in an outer lane and drove on round to
  the junction, 1,486 m.
- **Independence on the full matrix.** Step 2's race over the line (the first race from
  Leszczyńska behind the slow test player, 16 %) is inside it at 13 %: she holds the lane she
  moved to and is past 17 s into the race. The one over it now is the same race in Busy traffic
  with a player who never moves (16 %): she waits 12 s, stands 8 s behind the player's car, makes
  a U-turn in the street and goes the longer way by Dobra. That is the block again, at its price
  when she can turn back, and it goes with step 4b's way round. The mark stays recorded fail.
  In Busy traffic as a whole the player's place no longer sets a rival's time: 31 races, 7 %
  either way on average, where step 2's rivals were 15 % faster with the player than alone.
- **Passes traffic, No ghosting, Recovers, Honest car.** The faults are the old driver's and the
  counts moved a little, mostly down: steps 4a and 4b. Passes traffic turns with the draw of the
  town's cars (8.2 s in this run on Książęca, behind a car in the lane she needs for her turn).

The crash's own part passes today: a knock costs a rail car only the stop (it cannot be spun off
its line), and the wreck stands where there is a lane to go round in. It stays in the matrix for
the driver that can leave its line.

After step 4b (2026-11-13), on the 272 races of step 4b's bench (every race in traffic in three
draws of the town's cars), with step 4a's driver on the same races in brackets:

| Mark | Quick matrix (21 races, Pani Halina) | Full matrix (272 races, all six rivals) |
| --- | --- | --- |
| Finishes | pass: 20 of 20 | passes in the cloud (**once:Linux** until the Mac agrees): 271 of 271 (268) |
| Independence | passes in the cloud (**once:Linux**): 11 % on clear roads | **fail**: clear roads 11 % (12 %); in traffic 31 % for the worst pair over its draws (52 %), 47 % in one race (169 %), but 13 of the 46 pairs over 15 % (3 of 45) and the mean pair 10.2 % off (6.1 %): a rival that queues honestly is further from the one expected delay it pays out of sight |
| No crawl | pass: 1.7 s | pass: 2.4 s (2.3 s) |
| Passes traffic | **unsteady**: 2.9 s in this draw | **fail**: 6.9 s (6.5 s); more than 4 s in 13 of the 196 races in traffic (14) |
| No ghosting | passes in the cloud (**once:Linux**): no car driven through (17 after step 4a) | **fail**: 91 cars (444), 32 of them head-on (114); 36, 34 and 16 by draw in Busy traffic (128, 129, 140) |
| Re-routes | pass: 1 of 1 | pass: 9 of 9 |
| Recovers | passes in the cloud (**once:Linux**): never moved by the game in view | **fail**: 6 times (170) |
| Honest car | **fail**: stopped dead once (16 after step 4a) | **fail**: stopped dead 62 times (382). Sideways 20.5 m/s² in one race (12 races over the car's 19, 23.6 at the worst): 32 km/h through a 119° turn in a junction of Leona Kruczkowskiego. Pull 15.6 m/s² in one race (the car's 15) |
| Route sense | pass | **fail** in this draw: Pani Halina from Leszczyńska in Busy traffic takes 275.8 s her own way and 217.8 s sent by Topiel (it passed with step 4a's driver) |
| Skill ladder | not judged | pass, the same times (clear roads did not change) |
| Same race twice | pass | pass |

What it costs: a rival that queues like a car is slower among the town's cars. Alone, the mean
race in Busy traffic takes 172.9 s (131.0 s) and the rival stands 35.6 s of it (8.6 s); in Low
traffic, the game's own level, 107.7 s (96.8 s); on clear roads 84.7 s (84.7 s). Against the
"average" test player in Busy traffic the rival wins 26 races of 36 (32). The delay a rival pays
out of the player's sight was fitted again to the new driver (`RACE_STUCK` 0.77, 0.44, 0.46,
`RACE_STUCK_END` 0.7, `RACE_STUCK_LIGHTS` 7.4; the old numbers made a race 16.5 % too short).
[5.3](#53-step-4b-as-built-sight-the-sideways-move-the-pass-the-way-round) says what is left.

**After step 6a** (2026-11-13, the cloud's full matrix of 304 races, three draws in traffic).
Step 6a changes no rival's pace, and the bench says so: against main every race on clear roads
has the same time but Słoik's (0.4 to 0.6 s for the moment his satnav thinks again) and Halina's
blocked ones; in traffic the times of Bartek, Seba, Zbyszek and Mike are the same race for race,
and Halina's mean goes from 172.4 to 166.0 s over 158 races (her home district's shortcuts).

| Mark | Full matrix, step 6a |
| --- | --- |
| Finishes | passes: 303 of 303 (recorded once:Linux) |
| Independence | **fail**: 11 % on clear roads; in traffic 37 % for the worst pair over its draws, 63 % in one race (31 and 47 % after step 5b: Halina's first race from Leszczyńska in Busy traffic behind a player who never moves) |
| No crawl | pass: 2.3 s |
| Passes traffic | **fail**: 20.6 s; more than 4 s in 18 of 217 races in traffic |
| No ghosting | **fail**: 98 cars driven through (31, 31 and 27 by draw in Busy traffic) |
| Re-routes | pass: 9 of 9 |
| Recovers | **fail**: moved by the game in view 6 times; 9 of 9 crashes recovered |
| Honest car | **fail**: one corner at 20.5 m/s² (19), one pull of 15.6 m/s² (15), stopped dead 63 times |
| Route sense | passes for the first time on the full matrix: 2 of 2 free choices within 5 % (recorded once:Linux, not held until the Mac's run) |
| Skill ladder | pass: 59.6, 59.6, 52.7, 48.6, 45.9 and 43.4 s on the short course; Słoik ties Halina there |
| Ladder curve | pass (new): SŁOIK 6.9 %, BARTEK 5.7 %, SEBA 7.7 %, ZBYSZEK 5.8 %, MIKE 5.6 % over three courses |
| Told apart | pass (new): 1277 of 1277 turns indicated; no indication in Seba's 39 races; flashes Seba 212, Mike 110, Zbyszek 81, Bartek 58, Halina and Słoik 0; 18 of 18 wrong turns followed by the hazard lights |
| Yard links, Wrong-way hops, Same race twice | pass, as before |
| Wrong-way hops in traffic | passes: 2 hops taken, 4 refused, no car met (once:Linux) |

Told apart is recorded as a plain pass though it reads races in traffic too: it holds a rule
about each light (it follows what the driver does), not a count that moves with the draw.

**After step 6b part 1** (the pack on the race session, 6.2). The 304 old races are the same as
main's. Two marks are new: **Pack order** passes (quick and full matrix: on clear roads with no
player the club comes home in the order of its racers' own pace, all home), and **Pack in
traffic** passes on the cloud machine and is recorded `once:Linux` until the Mac's run (full
matrix: 16 of 16 club racers home in the pack's two races in Busy traffic; before the merge rule
of 6.2 three of eight missed the bench's 420 s with nobody near). The quick matrix is 40 races
(it was 24), the full one 344 (it was 304).

**After step 6b part 2** (the police chasers on the racers' driver, 6.3). The 344 old races are
identical to main's (only the session's wall-clock fields differ). Two marks are new: **Chase
keeps off** passes (recorded pass on the quick matrix, `once:Linux` on the full one) and **Chase
balance** passes (full matrix: the medians are 0.09 to 0.20 of the limit, the worst 1.43, the
second chaser at 20 s on one course). The quick matrix is 41 races (it was 40), the full one 416
(it was 344: 72 chase rows). Dead stops 80 to 84, four of them among the new chasers (Honest car
is a known fail of the rebuild).

**After step 6b part 3** (the crazy drivers on the racers' driver, 6.4). The 416 old races are
identical to main's (only the wall-clock fields differ). Two marks are new: **Crazy pace** passes
(full matrix: taxi x1.07, courier x1.04, Pasatini x1.06) and **Crazy stays crazy** passes (cut-ins
near the player 11 / 16 / 7; recorded pass on the quick matrix, `once:Linux` on the full one).
No crawl reads 3.0 s (it was 2.3), at its limit: the 3.0 s is an old-driver crazy row on Powiśle.
The quick matrix is 42 races (it was 41), the full one 488 (it was 416: 72 crazy rows).

**The Mac's run, 2026-11-14** (F's go; `--write` on main c7dc5f86). Every mark recorded
`once:Linux` passed on the Mac too and is now recorded pass: Independence, No ghosting and
Recovers on the quick matrix; Finishes, Route sense, Wrong-way hops in traffic, Pack in traffic,
Chase keeps off and Crazy stays crazy on the full one. The full matrix's known fails stay fail as
recorded (Independence 41 % in traffic, Passes traffic 18.7 s, No ghosting 152 cars, Recovers 4,
Honest car 15.6 m/s²). Told apart on the Mac: 1457 of 1457 turns indicated, 0 indications from
the rival who never indicates, 18 of 18 wrong turns followed by hazards; flashes Seba 205, Mike
104, Zbyszek 74, Bartek 58, Pani Halina and Słoik 0.


### 7.5 What the bench does not see

- **The city.** It has the lane graph only: no walls, kerbs or street furniture. Today's rail
  driver needs none. The new driver's free width comes from the graph's lanes and from race links,
  and a link's real shape is proven by the player's physics car in the city (step 5's check).
- **Heights.** The bench's map is flat. The one rule of step 3 that reads a height (a road
  through a finish's circle counts on the finish's own level) was run once on the real map with
  its terrain and decks: 12 roads at 8 finishes, each within 0.3 m of its finish's level, and
  the riverside road 8 m under the east end of Most Poniatowskiego left out.
- **The player's physics car.** The test player is a ghost on the lanes. A hit between a racer
  and the real car, and what a real player does to block or shove, is for Autopilot and the phone.
- **Whole-game races.** `tools/race_ai.sh` (every rival against the autopilot with the city
  built, about 5 minutes a race) stays for the ladder's table of times and the HUD. A whole-game
  race is not exactly repeatable: of five runs of the same race with `--fixed-fps 60`, four gave
  the same log line for line and one differed in its last second (the rival braking behind the
  player's car). That is one more reason the marks are judged on the bench.
- **The planner's cost on the phone.** The search is measured on a desktop (0.6 ms a frame in
  slices, a plan in under a second of the countdown). The phone's figure needs a phone run.
  The same for a stretch of line built during a race (step 4a: 1.5 ms in the middle, 2.3 ms at
  the most on the cloud's CPU).
- **Since step 4b in the matrix** (they were gaps here): the Low traffic of the whole game,
  the wide street, the course of `--race=0`, the final's last stretch, the ladder on other
  courses, and more than one draw of the town's cars for every race in traffic.
- **A top rival that is behind.** The fast test player is 3.7 s slower than Mordor Mike on clear
  roads, so no race of the matrix has him far enough behind the player to push (a second and
  more), and his push through the corners (section 6) is held by `check_first10.gd` alone. A test player that
  drives all of the car belongs with step 4b's driver.
- **Feel.** After each step that changes the game: an Autopilot race on the Mac from main, and
  three questions for F on the phone: did a racer ever look like traffic, did one do something
  your car cannot, and could you tell why you won or lost. For step 3 also: how a rival backing
  out of a blocked street or turning round in it looks.

Two things about the numbers themselves:

- **Busy traffic is a draw.** The same race with the same seeds comes out the same every time
  (Same race twice). But a race in Busy traffic depends on where the town's cars happen to be:
  the same Halina took 130.8 s in one draw and 144.8 s in another, and any change to how a racer
  uses the dice moves the draw. So a traffic number is read across a run's draws and not as one
  race, and a mark that turns with the draw is recorded unsteady (7.4) until the driver that
  fixes it is in.
- **Between machines.** Step 1's driver on the Mac gave the quick matrix identical to the cloud's
  Linux run, line for line. The full matrix gave the same marks with two traffic numbers apart
  (7.4 s behind a slower car against 10.2 s, 217 cars driven through against 216, stopped dead 184
  times against 187), all three from races in Busy traffic. With step 4a's driver the quick
  matrix gives the same marks on both machines (Independence 11 % on both), and the full one
  does not: Independence reads 22 % on the Mac and 13 % in the cloud (17 and 16 % at step 3),
  156 cars are driven through against 150 (134 against 152), and the game stops a rival dead
  136 times against 130 (140 on both). The races on clear roads are the same on both. So the
  Mac's run of a race in traffic counts as one more draw of the town's cars, and no more than
  that. Since step 4b the marks are read that way: over three draws on each machine, and a
  traffic mark is a pass only when both machines say so (7.4).

## 8. Build order

Eight pull requests, each small enough to review and each with the bench's numbers before and
after. Step 2 ends the complaint in F's message. The steps after it make racing good.

| Step | Pull request | What the player notices | Marks that turn |
| --- | --- | --- | --- |
| 1 (done) | Race bench, prototype race, baseline of today's driver, this plan in the repo | Nothing changes in the game | The baseline is recorded |
| 2 (done) | Skill profiles replace the band, in the ladder races, the final and the guided first race; an easier rematch after a loss | Halina and the others race from start to finish at their own pace. A slow player loses, and the rematch is a little easier | No crawl, Skill ladder, Independence on the quick matrix (the full matrix's last case turns with 4b) |
| 3 (done) | Route planner by arrival time; turning back at a blocked street; the expected traffic delay out of sight; a lane held for 2 s; one finish line for both cars | Rivals take different streets in traffic, go round a blocked street, get past a slow player on a two-lane road, get no empty streets out of sight, and finish where the player does | Re-routes; Finishes on the quick matrix; Independence in traffic both ways (the full matrix's last case turns with 4b) |
| 4a (done) | Driver, part 1: a racing line inside the racer's lane and a speed for every metre of it; the rivals' skill numbers set again for a real sideways pull; the centre-line pass by the oncoming lane it uses, clear for as long as the pass lasts | Smooth corners with the braking done before the bend, and no bend taken faster than the player's own car could. A rival rarely sits behind a slow car with the way past free | Honest car's grip (109 of the 110 races were over the car's limit, none is). The times were kept, not bettered: the line stays in its lane until 4b. Independence on the full matrix passes or fails with the draw of the town's cars and is recorded unsteady |
| 4b (done) | Driver, part 2: overtaking (a pass whose length comes from both cars' speeds and the racer's pull and that can be given up, nobody beside it on the way out, a smooth sideways move that ends before the corner, a side held while there is more to pass), collisions (a car across a junction is seen, no car put down in a racer's way), recovery | Real passes. Nobody drives through a car. A crashed rival reverses and goes on | Passes traffic, No ghosting, Recovers, Finishes, Honest car (the dead stops, the slide of a pass); Independence on the full matrix, once it is judged over several draws (no turning back behind a player's car that only waits) |
| 5 (done) | Race links: alleys, courtyards, car parks (5.4) | Halina turns into a courtyard and comes out in front | Real-car proof for every link (37 links proven, 15 refused) |
| 5b (done) | Wrong-way hops on one-way streets, for Seba and Mike (5.5; F's yes to question 3) | Seba and Mike dart the wrong way down a short one-way street when it is empty | Wrong-way hops, and in traffic (48 hops proven, 4 refused) |
| 6a (done) | Personalities, visible decisions, result card with both routes, tuning (6.1) | You can tell Seba from Zbyszek by how they drive | The ladder's curve of times (Ladder curve, Told apart) |
| 6b-1 (done) | One race session (`race_session.gd`) for the ladder races, the guided first race, Trzy mosty and the night club's pack race (6.2) | The club's drivers race like the ladder's rivals: own skill each, real overtakes, shortcuts, no driving through each other, none faster than your car | Pack order (new); Pack in traffic recorded fail; the 304 old races identical to main |
| 6b-2 (done) | Police chasers on the racers' driver (`police/chase_route.gd`, `ladder.gd` `POLICE`, 6.3) | Police cars in a chase brake for corners and take a proper line, and are as easy or hard to shake off as before | Chase keeps off, Chase balance (new); the 344 old races identical to main |
| 6b-3 (done) | Crazy drivers on the racers' driver, on fares (`crazy_route.gd`, `ladder.gd` `CRAZY`, 6.4). Step 6b is done | Taxis, couriers and the Pasatini drive to a fare across town and take proper racing lines, and still cut in, run reds and speed. Every race in the game uses the new driver | Crazy pace, Crazy stays crazy (new); the 416 old races identical to main |

Every pull request waits for green checks and the audit before it merges.

## 9. Parked questions

None blocks the work. Each has the default being built (also in docs/QUESTIONS.md).

1. **Should the first race stay a guaranteed win?** Answered by F on 2026-11-10: "Keep it real,
   as built". It was scripted so that a new player won
   narrowly, and that script was the crawl F saw. Built in step 2: easy but real. Halina drives
   her gentle day at her own pace and no longer copies the player, until the player has beaten
   her once. A player who races wins; a player at town pace or one who stops loses, the guide
   goes on either way, and each loss in a row makes her 5 % slower. Measured in the whole game's
   replay, whose autopilot drives cautiously: one win and two losses in three runs, all within
   11 s. The other honest answers, if F wants a surer first win: a head start at the line, a
   shorter first race, or the gentlest profile the crawl line allows (a share of 0.58).
2. **Should a rival get easier after the player loses to them?** Built in step 2: yes, 5 % slower
   for each loss in a row (from the first loss, not the second), 15 % at most, a win puts it
   back, and a race given up does not count.
3. **May aggressive rivals drive the wrong way down a one-way street?** Answered by F on
   2026-11-13: yes, as planned. Built in step 5b (5.5): Seba and Mike only, one block of 150 m
   at most, only where the player's car has driven the same, and only when the street is empty.
4. **How rough may rivals be?** Default: they defend their line and lean on the player in a pass,
   and they never ram the player off the road on purpose.
5. **Is Trzy mosty too hard now that Seba finishes where the player does?** Built in step 3: one
   finish line for both cars (5.1). At the end of every final Seba, and the minimap's line,
   used to go 682 m round to the stadium finish's junction, while a player who drove straight
   on in the avenue's left lane was home after 132 m, about 24 s sooner. Now both are home
   there. If the final is too hard without that gift, his pace in the final comes down
   (`ladder.gd` `FINAL_RACER`); if its last dash is too short, the finish moves further on
   (`trzy_mosty.gd` `FINISH_MIN`, counted to the circle).
