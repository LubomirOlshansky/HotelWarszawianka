# Race AI: the audit, the new design and the race bench

**Status (2026-11-09):** step 1 of 8 is built: the race bench, the prototype race and the recorded
baseline of today's driver. Nothing in the game changed with it. The build order is in
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
| 1 | Speed is tied to the player. The band aims Halina 15 m behind the player (30 m in front in the guided first race) and can cut her to 15 % of her top speed | She crawls when you are slow, waits when you stop, lifts off before the finish | 2 |
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
| The guided first race with Pani Halina (`rivals.gd` `first_speed`) | A special band: she holds 30 m in front at the player's own pace, then lets the player catch her | Same driver. Whether it stays a guided lesson is parked question 1 |
| Trzy mosty, the ladder final against Seba | Rail racer with a weak band | New driver, the long route over the three bridges |
| Night club pack race (`street_meet.gd`) | Several rail racers at full speed with every shortcut, no band | Same driver, one race object for the whole pack |
| Police chasers (`police.gd`) | Rail racer that never passes the player | The driver with a chase goal, later |
| Crazy drivers (`crazy_drivers.gd`) | Rail racer with no route | The driver with an aggressive profile, later |
| Drag race at the night club | A simulated run, no driving | Stays |
| Courier bike race | Its own rider on the footways | Stays, may share the route planner later |
| Boat race on the Vistula (`boat_race.gd`) | Its own boat driver | Stays |

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

## 6. Difficulty from skill, and the personalities

No racer's speed depends on the player's. A rival is hard because of how that rival drives, and
the ladder becomes a row of drivers. Four things replace the band:

- **Skill per rival, fixed for the race.** Halina brakes early and corners gently. Mike uses
  nearly all of the car.
- **Effort.** A racer far in front manages the lead at no less than about 85 % of their own pace.
  A racer behind pushes and takes more risk, which also brings more mistakes. Effort follows the
  time gap and never the player's speed, so nobody waits and nobody lifts off before the finish.
- **Fair out of sight.** Traffic exists only near the camera, so a racer the player cannot see
  pays the expected traffic delay as lost time.
- **An easier rematch, not an easier race.** After two losses in a row to the same rival, that
  rival is a little slower next time. It happens between races, never during one (parked
  question 2).

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
next time.

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
12 m behind it) and the 5.6 s of challenge line and countdown before the start.

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
tools/race_bench.sh                    # the full matrix: 107 races, about 4 minutes
tools/race_bench.sh --quick            # the quick matrix: 21 races, 30 s (verify step `racebench`, in CI)
tools/race_bench.sh --only=tamka/heavy/none --trace   # some races, with what the rival does once a second
tools/race_bench.sh --out=before       # on main: build/race_bench/before.json ...
tools/race_bench.sh --against=build/race_bench/before.json   # ... then on the branch, both runs side by side
tools/race_bench.sh --write            # record both matrices' marks (when a change moves one on purpose)
```

The quick matrix is Pani Halina from Tamka: a ladder race on clear roads against all six test
players, in Busy traffic against four, the blocked street and the crash; the guided first race
against four; the free choice from Leszczyńska and its three forced routes; one race twice. The
full matrix adds every test player to both tunings, both starts under every situation, two more
draws of the traffic, the forced routes in traffic, and the other five rivals on clear roads and
in traffic.

A race prints one line (its id is `rival/tuning/start/situation/player`), then what went wrong:

```
halina/ladder/tamka/heavy/none   137.8 s x1.00   45 km/h (top 104) · crawl 2.9 s (longest 0.9) · behind 5.6 s · stood 8.7 s · passed 14 · pace x1.00-1.00 · Tamka > Solec > ... · 33 cars, 3.3 s
    THROUGH 8 cars (37.1 s a car on Leona Kruczkowskiego, ...) · 3 slips (3 seen) · touched 2 cars · stopped dead 5 times (15.1 s from 65 km/h on Solec, ...) · sideways 76 m/s²: 99 km/h through 48° in 8 m on Książęca (357, 429) at 88.2 s · passed by 2 town cars
```

`x1.00` is the time against the same situation with no player, `pace` the range of the band's
multiplier, the last two numbers the town's cars round the rival and the seconds the race took to
run. A fault comes with its place, so it can be looked at in the game (`--at=357,429`). With
Godot's own `--verbose` every car driven through is printed with both cars' states.

### 7.3 The pass marks

`race_bench.gd` `judge` turns a set of races into eleven marks. The limits are constants at the
top of that file; a change that moves one says why in its PR.

| Mark | Passes when | Step |
| --- | --- | --- |
| **Finishes** | every race reaches the finish within 420 s | 4b |
| **Independence** | with a test player the rival's time (from the moment it is let go) is within 15 % of its time with no player on the same roads, and a race it finishes alone it finishes with any player. In traffic only slower counts: the town's cars are where the view is, so a player left behind means emptier streets round the rival | 2 |
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
- a mark recorded **fail** that fails is the known state of the rebuild, listed in the OK line.

So each step turns marks from fail to pass on purpose, and nothing slips back.

| Mark | Quick matrix (21 races, Pani Halina) | Full matrix (107 races, all six rivals) |
| --- | --- | --- |
| Finishes | **fail**: 19 of 20 (the first race from Tamka with a player who never moves) | **fail**: 104 of 106 (the same race on clear roads and in traffic) |
| Independence | **fail**: her time moves up to 145 % with the player | **fail**: up to 171 %, and 2 races she finishes alone never finish |
| No crawl | **fail**: 46.2 s in a row | **fail**: 69.2 s (the first race, a slow player) |
| Passes traffic | **fail**: 5.6 s behind a slower car with a free lane beside it | **fail**: 10.2 s (Mordor Mike) |
| No ghosting | **fail**: drove through 22 cars | **fail**: 216 cars (and touched 68) |
| Re-routes | **fail**: 0 of 1, drove through the wall | **fail**: 0 of 9 |
| Recovers | **fail**: moved by the game in view 14 times; the crash itself recovered | **fail**: 103 times; 9 of 9 crashes recovered |
| Honest car | **fail**: 84 m/s² sideways against the car's 19; stopped dead by the game 18 times | **fail**: the same bend and junction; 187 times |
| Route sense | pass: her own choice 91.2 s, the best forced route 93.1 s | pass: in traffic too (161.5 s against 160.3 s) |
| Skill ladder | not judged (one rival) | **fail**: the top rival 3 % faster than the first, Słoik slower than Halina |
| Same race twice | pass | pass |

The crash's own part passes today: a knock costs a rail car only the stop (it cannot be spun off
its line), and the wreck stands where there is a lane to go round in. It stays in the matrix for
the driver that can leave its line.

### 7.5 What the bench does not see

- **The city.** It has the lane graph only: no walls, kerbs or street furniture. Today's rail
  driver needs none. The new driver's free width comes from the graph's lanes and from race links,
  and a link's real shape is proven by the player's physics car in the city (step 5's check).
- **The player's physics car.** The test player is a ghost on the lanes. A hit between a racer
  and the real car, and what a real player does to block or shove, is for Autopilot and the phone.
- **Whole-game races.** `tools/race_ai.sh` (every rival against the autopilot with the city
  built, about 5 minutes a race) stays for the ladder's table of times and the HUD. A whole-game
  race is not exactly repeatable: of five runs of the same race with `--fixed-fps 60`, four gave
  the same log line for line and one differed in its last second (the rival braking behind the
  player's car). That is one more reason the marks are judged on the bench.
- **Feel.** After each step that changes the game: an Autopilot race on the Mac from main, and
  three questions for F on the phone: did a racer ever look like traffic, did one do something
  your car cannot, and could you tell why you won or lost.

## 8. Build order

Eight pull requests, each small enough to review and each with the bench's numbers before and
after. Step 2 ends the complaint in F's message. The steps after it make racing good.

| Step | Pull request | What the player notices | Marks that turn |
| --- | --- | --- | --- |
| 1 (done) | Race bench, prototype race, baseline of today's driver, this plan in the repo | Nothing changes in the game | The baseline is recorded |
| 2 | Skill profiles replace the band, in the ladder races and in the guided first race | Halina and the others race from start to finish. A slow player loses | Independence, No crawl, Skill ladder |
| 3 | Route planner by arrival time | Rivals take different streets and go round a blocked one | Re-routes; Route sense in traffic |
| 4a | Driver, part 1: racing line and a speed for every metre | Fast, smooth corners with the braking done before the bend | Honest car (grip), better clear-road times |
| 4b | Driver, part 2: overtaking, collisions, recovery | Real passes. Nobody drives through a car. A crashed rival reverses and goes on | Passes traffic, No ghosting, Recovers, Finishes, Honest car (brakes) |
| 5 | Race links: alleys, courtyards, car parks, wrong-way hops | Halina turns into a courtyard and comes out in front | Real-car proof for every link |
| 6a | Personalities, visible decisions, result card with both routes, tuning | You can tell Seba from Zbyszek by how they drive | The ladder's curve of times |
| 6b | One race object for the pack race, Trzy mosty, police chasers and crazy drivers | Every race in the game uses the new driver | All marks on every race mode |

Every pull request waits for green checks and the audit before it merges.

## 9. Parked questions

None blocks the work. Each has the default being built (also in docs/QUESTIONS.md).

1. **Should the first race stay a guaranteed win?** Today it is scripted so that a new player
   wins narrowly, and that script is the crawl F saw. Default: easy but real. Halina drives a
   gentle, steady pace and no longer copies the player. A player who stops loses and gets the
   retry she already offers.
2. **Should a rival get easier after the player loses to them twice in a row?** Default: yes, 5 %
   slower per loss, 15 % at most, and a win puts it back.
3. **May aggressive rivals drive the wrong way down a one-way street?** Default: Seba and Mike
   only, for 150 m at most, and only where the player's car can do the same.
4. **How rough may rivals be?** Default: they defend their line and lean on the player in a pass,
   and they never ram the player off the road on purpose.
