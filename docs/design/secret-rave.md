# Sekretny rave: the secret techno rave quest line

F's ask (2026-11-06): techno raves with DJ lights by day and by night, a MORDOR FM line where LEKTI
invites you to a secret rave, and a quest where Ziomek calls and you drive him there. Then: a
Berlin-style door with three questions at Smoła, and an inside you can enter (option A, the
cutaway room). The research and the options are in the proposal doc
(https://claude.ai/artifact/7tokY91ceM47L35qqM1psa). Code: `game/scripts/rave.gd` (rigs, quest,
door), `game/scripts/club.gd` (the room), lines in `game/data/dialogue.json`, check
`game/tools/check_rave.gd` (verify step `rave`).

Everything is invented: LEKTI is a fictional pirate host, Ziomek a fictional friend, Smoła and
Pan Kołek a fictional club and doorman. No real crews, DJs, venues or brands; no drug jokes.

## The raves

| | When (game clock) | Where | What you see |
| --- | --- | --- | --- |
| Night rave | Thu-Sat nights, 22:00-06:00 | one of three spots a weekend: under the Poniatowski viaduct, a depot past the tracks in Praga, a hall by the railway towards Ochota | booth, stacks, truss, 46 dancers on the beat, six beams into the sky, a laser fan, a strobe cone (lit look only) |
| Day rave | Fri-Sun, 12:00-20:00 | the Praga beach under Most Poniatowskiego (F, 2026-11-07: the sand under the east arch, by the pier) | the booth and a crowd in colour, no lights |

A techno thump plays by the active spot and the crowd talks (`rave_crowd`, tags night/day). Far
away nothing is drawn (RIG_FAR 1.4 km).

## The quest

1. **LEKTI.** On a rave evening (19:00-04:00) with nothing else on, LEKTI breaks into MORDOR FM:
   one of five lines (`rave_lekti`) and the night's password (BETON, SYRENA, MGŁA, TRAMWAJ ZERO,
   PRAGA 97, BAS, NEON, PERON). He is heard as well as read: each line and each password is a
   voice clip (below), the music dips under it. On other stations the regular host only passes on
   the rumour (`rave_rumour`), so the password is MORDOR FM's.
2. **ZIOMEK DZWONI.** A minute later Ziomek rings (the call card, ODBIERZ / ODRZUĆ, then JADĘ! /
   NIE DZIŚ). The calls alternate: a secret rave, then a club night at Smoła.
3. **Pickup.** The dashed ring at his block, 400-900 m away; he tunes the radio to MORDOR FM.
4. **Meeting point** (secret rave only). The arrow says "???": he knows only that much. A hooded
   man there gives the spot (`rave_meet`).
5. **The door.** Stop at the door ring: the bouncer asks three questions (SELEKCJA 1/3...). At a
   secret rave one of them is the password. All three right: Ziomek pays the ride (+150 zł,
   +40 respect) and the ticket is 50 zł, cash only (F, 2026-11-06; the card machine "temporarily
   down since 2019"): PŁACĘ 50 ZŁ goes in, POTEM leaves it. Short of cash: a toast, no entry.
   The first wrong answer: "Nie tym razem. Wróć później." and half the fare.
6. **Inside** (Smoła, and a secret rave you get into): the cutaway room.

✕ gives up at any step (Ziomek takes the night bus). Other calls are paused while it runs.

### The door questions

Eight questions in the spirit of a strict Berlin door, never about looks: who is playing (you
don't know, you're here for the night), how many you are (two), where you were before, the phone
(stays in the pocket, sticker on the camera), what you drink, how long you stay (till morning),
why so smiley, what kind of night it is. Each has one right answer and two wrong ones, shuffled.

## The room (option A: cutaway, watch and tap)

A 24 × 16 m room built far off the map (9 km away), seen like F's reference picture: the back and
left walls cut away, the camera fixed at 45°. The city stays loaded and the car waits. Inside: the
DJ on a riser with stacks and a truss, the bar with lit bottles, the cloakroom, a sofa, toilet
doors, the WYJŚCIE door, 44 dancers, Ziomek, the barman, the cloakroom lady, and Pan Kołek, the
long-coated man in sunglasses by the wall (our own parody of a film vampire hunter).

- **Tap a person:** a line about the scene (DJ, bar, crowd, Ziomek, Pan Kołek; `club_*`).
- **TAŃCZ:** tap on the beat (132 BPM); eight in a row pays respect (up to three times a night).
- **Red light moment:** now and then the lights go red and the DJ says something (`club_red`).
- **WYJDŹ** (or Esc): back to the car at the door.

**The jungle** (F's photo of a jungle-dressed booth): palms by the pillars and in the corners,
vines hanging from the trusses and the walls, big leaves round the riser, ferns in pots, all in
the room's one mesh.

**The patio** (F's photos of a courtyard club garden): PATIO (the green-lit door behind the bar)
goes out to a tenement courtyard next to the room: white walls with windows and balconies, a
wooden deck with red deck chairs under a truss, three trees full of fairy lights, garlands of
bulbs, a mirror ball whose rays turn, the bar kiosk, a small DJ table in the plants, a crowd that
chats and sways. The music is lighter there (PÓŁNOC FM), the room's kick muffled through the
wall. Tap the barmaid, the patio's DJ or anyone (`club_patio`, `club_patio_bar`,
`club_patio_dj`). SALA goes back in.

Cost: one room mesh, the dancers' MultiMesh and the lights' MultiMesh (3 draw calls in the room,
3 on the patio; the city is not drawn then; about 13k triangles for both). The rig outside: four draw calls near an active spot.

## LEKTI's voice

Generated with ElevenLabs (F's Creator plan, commercial licence), the project's MORDOR FM
announcer voice, model eleven_v4, 2026-11-06. Files in `game/audio/rave/`: `lekti_1..5.ogg` (one
per `rave_lekti` line, in order) and `pw_<word>.ogg` (one per password, cut from one take on its
silences), trimmed, -18 LUFS like the opening line, Vorbis mono. A new line in `rave_lekti` needs
a new clip (check_rave fails without one).

## Left for later

In docs/BACKLOG.md "Secret rave": PixelLab portraits and icons, the phone's feel and cost, the
dawn after, Opaski (wristbands), other cards popping up during the quest, the walk-around room
(option B), LEKTI tunes from MORDOR FM in the room.
