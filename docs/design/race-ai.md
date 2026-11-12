# Race AI: the audit, the new design and the race bench

**Status (2026-11-12):** steps 1 to 3 of 8 are built. Step 1 was the race bench, the prototype
race and the recorded baseline of the old driver. Step 2 took the rubber band out: every rival
drives its own skill from the line to the finish, whatever the player does
([section 6](#6-difficulty-from-skill-and-the-personalities)). Step 3 gave every rival a plan:
its streets by its own seconds to the finish with the town's traffic counted, another way round
a blocked street, no empty streets once the player is out of sight, and one finish line for both
cars ([section 5.1](#51-step-3-as-built-the-plan-the-way-round-the-towns-traffic)). The driving
under it (the rail car, its passes and its corners) is still the old one, for steps 4a to 6b.
The build order is in [section 8](#8-build-order).

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
| 3 | It plans its speed for the next junction only. It does not brake for bends along a street or look past the next corner, and its brakes stop at 10 m/s² | It arrives too fast: 99 km/h through a 48° bend, or stopped dead by the game behind a car | 4a |
| 4 | Corners follow the middle of the lane. There is no racing line and no cut apex | Slow, square corners | 4a |
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
| Night club pack race (`street_meet.gd`) | Several rail racers at full speed with every shortcut, no band | Same driver, one race object for the whole pack |
| Police chasers (`police.gd`) | Rail racer that never passes the player | The driver with a chase goal, later |
| Crazy drivers (`crazy_drivers.gd`) | Rail racer with no route | The driver with an aggressive profile, later |
| Drag race at the night club | A simulated run, no driving | Stays |
| Courier bike race | Its own rider on the footways | Stays, may share the route planner later |
| Boat race on the Vistula (`boat_race.gd`) | Its own boat driver | Stays |

Since step 2 the ladder races, the guided first race and Trzy mosty have no band: each rival
drives its skill profile, with an effort that follows the time gap (section 6). The pack race,
the police chasers and the crazy drivers never had one. All of them still drive the rail racer.

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
  race, Trzy mosty and the pack race; later the police chasers and the crazy drivers.

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
the last bridge, where the finish's own junction is 682 m round. Seba's last leg is planned to
the circle (5 s from the bridge against 30 s), so he no longer drives past the finish that the
player wins at: in the whole game, started at the last bridge, he is home in 26.7 s where he
took 51.1 s. The final's checkpoints keep junction plans, because a checkpoint is driven
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
both), so they stay. These are the old driver's numbers: when step 4b changes how a racer
passes, the tool is run again and the constants move.

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

## 6. Difficulty from skill, and the personalities

No racer's speed depends on the player's. A rival is hard because of how that rival drives, and
the ladder is a row of drivers. Step 2 built every point here but "fair out of sight", which
came with step 3's route planner.

- **Skill per rival, fixed for the race** (`ladder.gd`). Every rival has the player's car. What
  differs is how much of it the rival uses: the share of a road's racing speed held on the
  straights (`share`), the pull away from a corner (`race_accel`), how early the braking starts
  (`brake`) and the grip used in a corner (`lat`), each at or under the car's own. Halina brakes
  early and corners gently. Mike uses nearly all of the car.
- **Each rival's own dice** (`traffic.gd` `race_rng`). A wrong turn and a corner taken badly are
  rolled on the rival's own dice and happen whether the player is near or not, so they are part
  of its skill and of its time. Before, a mistake was rolled only near the player, on dice shared
  with the town's cars.
- **Effort** (`rivals.gd` `effort_of`). The one thing left of "keeping the race close". It
  follows the time gap to the player and never the player's speed. From 1 s behind to 3 s ahead a
  rival drives its own pace. Further ahead it manages the lead, down to 0.9 of its pace from a
  10 s lead on. Further behind it pushes, up to 1.04 from 5 s behind on, the corners harder too
  and with one and a half times its mistakes. The effort moves at most 0.05 a second. So a
  rival's whole time moves by about a tenth at most whatever the player does, nobody waits, and
  nobody lifts off before the finish.
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
(1752 m), after step 3. The bench's Skill ladder mark holds the order of the times, not of any
one number.

| Rival | Share of the road's speed | Pull (m/s²) | Brakes (m/s²) | Grip (m/s²) | Time alone |
| --- | --- | --- | --- | --- | --- |
| Pani Halina on her gentle day | 0.65 | 7.0 | 4.0 | 5.0 | 108.0 s |
| Pani Halina | 0.70 | 8.0 | 4.5 | 5.5 | 99.2 s |
| Słoik z Radomia | 0.92 | 8.5 | 5.5 | 6.0 | 88.0 s, his wrong turn included |
| Bulwar Bartek | 0.80 | 9.5 | 6.0 | 7.5 | 86.7 s |
| Seba z Pragi | 0.83 | 10.5 | 9.0 | 11.5 | 80.3 s |
| Taksiarz Zbyszek | 0.92 | 11.0 | 7.0 | 10.0 | 75.6 s |
| Mordor Mike | 0.97 | 12.5 | 9.0 | 11.0 | 71.2 s |
| The player's car, for scale | 1.00 | 15 | 30 | 19 | 75.3 s (the fast test player) |

Before step 2 the six drove it in 73.7, 76.2, 73.7, 72.8, 72.3 and 71.7 s with no player, and in
180 s to 85 s with a player who never moved. Step 3 moved the times by half a second at most,
but for Słoik (92.9 s before): his wrong turn is another road now
([5.1](#51-step-3-as-built-the-plan-the-way-round-the-towns-traffic)). The easier rematch on the
same race: the gentle day takes 108.0, 112.4, 117.2 and 118.4 s after 0, 1, 2 and 3 losses in a
row, and Mordor Mike 71.2, 74.5, 78.0 and 82.2 s. No rival's share goes under 0.58: with the
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
| `heavy` | Settings → Traffic: Busy (two more draws of the town's cars in the full matrix) | pass slower cars and not drive through them |
| `blocked` | clear roads; parked cars across every lane, both ways, of a street on the rival's own route near 45 % of the way (one with another way round at most 1.6 times as long) | take another way |
| `crash` | clear roads; a wreck across its lanes near 35 % of the way (where there is a lane to go round in) and a knock from the side at 60 % (`traffic.gd`'s `DAZE` and `SHOVE_SLIDE`, 60 % of its speed lost) | go round, come back from the knock, finish |

The prototype race is F's: Powiśle to Plac Trzech Krzyży, from two starts. `tamka` (200, -400) is
where F raced; there is one obvious way. `leszczynska` (300, -790) in north Powiśle has three
useful routes within 15 s of each other, each forced through a point or two for the comparison:
`dobra` (Zajęcza, Dobra, Czerwonego Krzyża, Kruczkowskiego), `topiel` (Zajęcza, Topiel,
Kruczkowskiego) and `solec` (Jaracza, Solec, Ludna).

### 7.2 Running it

```zsh
tools/race_bench.sh                    # the full matrix: 111 races, about 4 minutes
tools/race_bench.sh --quick            # the quick matrix: 21 races, 30 s (verify step `racebench`, in CI)
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

### 7.3 The pass marks

`race_bench.gd` `judge` turns a set of races into eleven marks. The limits are constants at the
top of that file; a change that moves one says why in its PR.

| Mark | Passes when | Step |
| --- | --- | --- |
| **Finishes** | every race reaches the finish within 420 s | 4b |
| **Independence** | with a test player the rival's time (from the moment it is let go) is within 15 % of its time with no player on the same roads, faster or slower, and a race it finishes alone it finishes with any player. In traffic too since step 3: the town's cars are where the view is, and a rival beyond them pays the delay they would have cost it (before, only slower counted there, because a player left behind meant empty streets round the rival). A race the rival never finishes because the player's own stopped car stood in front of it with no lane to pass in, for more than half of the race, is not judged here: that is a block and not a pace that follows the player's (Finishes counts it, and step 4b's driver has to get round) | 2 |
| **No crawl** | never more than 3 s in a row under half of the road's racing speed on a free straight road: nobody within 30 m in front, the next 40 m of its own way bending less than 0.3 rad, not held at the line, not knocked, not on a junction's curve | 2 |
| **Passes traffic** | in Busy traffic never more than 4 s behind the same slower car (under 0.7 of the road's racing speed, within 12 m) while a lane beside it is free: another lane of its road with no slow car from 6 m behind to 30 m ahead, or the oncoming lane with no car for 80 m | 4b |
| **No ghosting** | never inside another car's box (traffic.gd's own test; the town's cars, parked ones and the player's) for 0.25 s or more. Less is a touch, the bump of a collision | 4b |
| **Re-routes** | with its street walled off it finishes, drives through no car, and takes no longer than its clear time stretched to the way of a driver who finds out at the wall (to the wall, back to the junction behind, round from there), times 1.2, plus 8 s | 3 |
| **Recovers** | never moved by the game in view (pushed through a car, or put somewhere else), and with the wreck and the knock it finishes, drives through no car and loses at most 12 s against the same race without them | 4b |
| **Honest car** | never over the player's car's top speed (108 km/h), pull (15 m/s²), sideways grip (19 m/s², measured as v² x turn / 8 m over every 8 m of its way) or brakes (30 m/s²: a harder stop is the game stopping the car, not the car) | 4a, 4b |
| **Route sense** | its own choice of route is at most 5 % slower than the best of the forced routes (on clear roads; in the full matrix in traffic too) | 3 |
| **Skill ladder** | flat out on clear roads with no player, each rival up the ladder is as fast as the one below (1 % slack) and the top rival at least 10 % faster than the first. Full matrix only | 2 |
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

So each step turns marks from fail to pass on purpose, and nothing slips back.

After step 3 (2026-11-12), with step 2's number in brackets where it moved:

| Mark | Quick matrix (21 races, Pani Halina) | Full matrix (111 races, all six rivals; step 2's numbers are of its 107) |
| --- | --- | --- |
| Finishes | pass since step 3: 20 of 20 (19) | **fail**: 109 of 110 (104 of 106), the first race from Tamka with a player who never moves, in Busy traffic: see below |
| Independence | pass since step 2: her time moves up to 11 % with the player (8 %, with one race not judged) | **fail**: up to 16 % (16 %), in one race: see below. Judged both ways in traffic now; by that rule step 2's driver was at 38 % |
| No crawl | pass since step 2: 1.7 s in a row (1.9 s) | pass since step 2: 2.7 s (2.4 s) |
| Passes traffic | **unsteady**: 8.2 s in this draw of the traffic (2.2 s) | **fail**: 8.2 s (9.2 s) |
| No ghosting | **fail**: drove through 5 cars (9) | **fail**: 152 cars (159) |
| Re-routes | pass since step 3: 1 of 1 (0 of 1, drove through the wall) | pass since step 3: 9 of 9 (0 of 9) |
| Recovers | **fail**: moved by the game in view once (7 times); the crash itself recovered | **fail**: 79 times (85); 9 of 9 crashes recovered |
| Honest car | **fail**: 49 m/s² sideways against the car's 19; stopped dead by the game 5 times (10) | **fail**: 77.6 m/s², Mordor Mike at 101 km/h through the bend on Książęca; 140 times (159) |
| Route sense | pass: her own choice 123.9 s, the best forced route 123.9 s | pass: in traffic too |
| Skill ladder | not judged (one rival) | pass since step 2: 99.2, 88.0, 86.7, 80.3, 75.6 and 71.2 s up the ladder, the top rival 39 % faster than the first |
| Same race twice | pass | pass |

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
  times against 187), all three from races in Busy traffic.

## 8. Build order

Eight pull requests, each small enough to review and each with the bench's numbers before and
after. Step 2 ends the complaint in F's message. The steps after it make racing good.

| Step | Pull request | What the player notices | Marks that turn |
| --- | --- | --- | --- |
| 1 (done) | Race bench, prototype race, baseline of today's driver, this plan in the repo | Nothing changes in the game | The baseline is recorded |
| 2 (done) | Skill profiles replace the band, in the ladder races, the final and the guided first race; an easier rematch after a loss | Halina and the others race from start to finish at their own pace. A slow player loses, and the rematch is a little easier | No crawl, Skill ladder, Independence on the quick matrix (the full matrix's last case turns with 4b) |
| 3 (done) | Route planner by arrival time; turning back at a blocked street; the expected traffic delay out of sight; a lane held for 2 s; one finish line for both cars | Rivals take different streets in traffic, go round a blocked street, get past a slow player on a two-lane road, get no empty streets out of sight, and finish where the player does | Re-routes; Finishes on the quick matrix; Independence in traffic both ways (the full matrix's last case turns with 4b) |
| 4a | Driver, part 1: racing line and a speed for every metre | Fast, smooth corners with the braking done before the bend | Honest car (grip), better clear-road times |
| 4b | Driver, part 2: overtaking, collisions, recovery | Real passes. Nobody drives through a car. A crashed rival reverses and goes on | Passes traffic, No ghosting, Recovers, Finishes, Honest car (brakes) |
| 5 | Race links: alleys, courtyards, car parks, wrong-way hops | Halina turns into a courtyard and comes out in front | Real-car proof for every link |
| 6a | Personalities, visible decisions, result card with both routes, tuning | You can tell Seba from Zbyszek by how they drive | The ladder's curve of times |
| 6b | One race object for the pack race, Trzy mosty, police chasers and crazy drivers | Every race in the game uses the new driver | All marks on every race mode |

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
3. **May aggressive rivals drive the wrong way down a one-way street?** Default: Seba and Mike
   only, for 150 m at most, and only where the player's car can do the same.
4. **How rough may rivals be?** Default: they defend their line and lean on the player in a pass,
   and they never ram the player off the road on purpose.
5. **Is Trzy mosty too hard now that Seba finishes where the player does?** Built in step 3: one
   finish line for both cars (5.1). Seba used to drive 550 m past the stadium finish to its
   junction at the end of every final, about 24 s, while the player was home at the circle. If the
   final is too hard without that gift, his pace in the final comes down (`ladder.gd`
   `FINAL_RACER`), not the finish.
