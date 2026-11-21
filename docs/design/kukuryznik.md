# Kukuryźnik: the e-scooter chaos (F, 2026-11-19)

F's ask: research the Polish meme and TikTok culture around KuKirin e-scooters and their riders,
then bring it into the game: scooters on bike lanes and streets, reckless riders, pedestrians
shouting and jumping out of the way, NPC lines, radio jokes and random chaotic encounters,
natural in the existing world. Built in `scripts/city_life.gd` (the riders), `scripts/pedestrians.gd`
(the leap), `data/dialogue.json` (the words), checked by `tools/check_kukuryznik.gd`.

## 1. The research (autumn 2026; reference only, nothing copied into the game)

- **Slang.** A reckless e-scooter rider is a *kukiriniarz* (also *kukiryniarz*, *kukuriniarz*);
  the scooter a *kukiryn*. From the KuKirin brand (formerly Kugoo Kirin) of fat-tyre scooters.
  naTemat: the word "sounds like a cartoon chicken's name". In the running for Młodzieżowe Słowo
  Roku 2026. Friends tease "Ty kukiriniarzu!". Not every owner is one (4funkids). Cousins:
  *surroniarz* (Sur-Ron e-motorbikes), *hulajnogarz*.
- **The look and the habits.** Teenagers (the most injured age group is 7-14), a G2 Max-type
  scooter with fat tyres, LED lights and a speaker playing music ("first you hear the music",
  hiro.pl), often two on one deck, wheelies, mostly no helmet, "tuned" past the limiter to 55 km/h
  and more. Pavements, bike paths and roads alike.
- **TikTok.** #kukiriniarz: dashcam and phone clips of kids riding illegally or falling; customs
  ("bestia"), wheelies, the Roblox copies; the riders' defiant replies to the "hate".
- **Warsaw lore.** The "Warsaw Mob" Telegram night rides through the centre that fled the police
  (TVN Warszawa, Sept 2025); a September 2026 clip on al. Prymasa Tysiąclecia of a scooter passing
  a car at 100 km/h ("Ja jadę sto na godzinę, a on jedzie dużo szybciej niż my", ~200k views in a
  day). The city's 12 km/h zones (Krakowskie Przedmieście, the boulevards, Złota, Zgoda, Bracka,
  Plac Centralny; scooter_zones.gd has four), helmets for under-16s, record ticket numbers.
- Sources: rozrywka.spidersweb.pl, natemat.pl, hiro.pl, 4funkids.pl, miastons.pl, zajekubki.pl,
  bezprawnik.pl, auto-swiat.pl (both pieces), autoblog.spidersweb.pl. TikTok blocks automated
  reading: only clip titles were seen.

## 2. The parody

- **KUKURYŹNIK** (F's pick, 2026-11-19): the chicken-name joke plus the *kukuruźnik*, the An-2
  crop-duster biplane, which buzzes the same and "flies lower". Riders: *kukuryźniarze*. The real
  name (and Kugoo, and TikTok) is on `data/brand_denylist.json`.
- Look: a dark deck, fat tyres, a cyan glowing strip under the deck and a lamp (LIT_SIGN, so they
  read at night), a magenta glowing speaker on the bar; the rider in a hoodie (the instance colour)
  with the hood up.

## 3. What happens

| Gag | Where and when | Words |
| --- | --- | --- |
| Riders | 1 near the view 07-14, 4 from 14-22, 3 till midnight, 2 till 02:30; 35% on a road's kerb edge (the couriers' roads), 25% on footways, the rest on cycle paths; 36-54 km/h; 25% two on one deck, 15% of the solos on one wheel | - |
| Walkers leap | a rider's line 3 m ahead: walkers within 3.5 m (footway) or 1.6 m (beside a path or kerb) hop aside to the far side of their footway, the ones walking into him turn round | `kukuryznik_walker` (any; `zone` inside a 12 km/h zone), one shout per 18 s |
| Near miss | the car's path: he swerves or hops as a Pędzik does | `kukuryznik` `near_miss` |
| Overtake | a kerb rider within 16 m behind the car at 25 km/h or more going his way: the car's speed + 4 m/s (up to 100 km/h), past, his line; back to his speed 40 m on | `overtake` |
| Wipeout / mum | every 90-200 s a rider 12-80 m from the view in sight: on the ground 7 s (scooter on its side, phone up) or on the phone 9 s; up and away when the car comes within 6 m | `gleba`, `mama` |
| Kebab gang | at night, one stand in three (a new set each day): three riders standing by their scooters beside the kiosk | `gang` for a car rolling by under 25 km/h, once a minute |
| Kukuryźnik Mob | 22:30-02:00, at most every 10 min: 5-7 riders in a column on one road, 4.5 m apart, taking the same way at every junction, gone after 2 min out of sight | `mob` |
| KEBAB FM | once a rider was seen by the car, at most every 7 min, radio on | `radio_host` `kukuryznik`, `kukuryznik_mob` |

## 4. Cost

One more MultiMesh (`Kukuryznik`, ≤ 14 instances, 204 triangles each, no sun shadow): +1 draw
call while one is in view, none otherwise. The step is the Pędziks' (15 Hz near, slower far and
off screen); the 2 Hz tick adds a leap test per rider (60 walkers each) and a few distances. The
walkers' leap is one more float test per walker per frame. Bench on the Mac and the phone: see the
pull request.

## 5. Open

- The horn: a biplane buzz instead of a bell (a recorded sound; a paid generator needs F's yes).
- The police and the mob ("znowu oni" from a patrol nearby).
