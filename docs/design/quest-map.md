# Quest map and quest starts (F, 2026-11-07)

F's ask: the beta needs a list where the big interactive quests can be started; the map should
show the main quest boldly ("like the Witcher, a big glowing blob"), the light street jobs
(kebab, deliveries) one plain icon each, and the big questlines' start points as something more
interesting than a job icon. Drive to a start and the friend starts talking in person ("siema,
let's do it") instead of phoning; phone calls stay too. While a quest runs, the other marks go,
because they are of no interest then. About 5 questlines now, about 10 later.

## What the big open-world games do

| Game | Main quest | Side content | During a quest | How quests start |
| --- | --- | --- | --- | --- |
| The Witcher 3 | gold "!" and the tracked objective's glowing gold area on the minimap and map | grey/white "!" for side quests, "?" for undiscovered places, small icons for shops and boards | the tracked quest's marker leads; the "?" and icon clutter stay (the most common complaint, and the studio admitted Skellige had too many) | walk up to an NPC with a "!", notice boards, overheard talk |
| GTA V | a letter blip per character (M, F, T) at story mission starts | small coloured icons for strangers and activities; shops and garages as their own icons | everything else hides on the radar; the route (GPS line) and the target blip remain | drive into a mission start's marker on the ground; phone calls and texts for follow-ups |
| Red Dead Redemption 2 | a yellow letter blip per story mission giver | white "?" / ! for strangers, small icons for activities | the minimap shows only the mission's blips and route | ride up to a giver, a cutscene starts in person; letters and telegrams for some |
| Cyberpunk 2077 | yellow main job icon, highlighted | many tiers of icons (gigs, NCPD, side jobs) | filters on the map; the HUD shows the tracked job only | fixers phone you, or you walk up to the giver |
| Ghost of Tsushima | no markers at all: the Guiding Wind points | foxes, birds and smoke lead to side content | nothing else to hide | walk up to a person; a short line starts the tale |

What carries over to a phone-sized isometric drive:
1. **Three tiers that never look alike.** One mark for the story (gold, glowing, the only thing
   that shines), one family for questline starts (a bigger badge in the questline's own colour
   with a "!", like the RDR2 and GTA letter blips), small plain icons for repeatable jobs.
2. **Declutter during a quest** (GTA, RDR2): the minimap shows only the quest's target and route.
   The Witcher's clutter is the cautionary tale.
3. **Starts in person** (RDR2, Ghost of Tsushima): you arrive, the friend walks up and talks, and
   the quest begins. Phone calls (GTA, Cyberpunk) stay for follow-ups and for players who never
   pass the spot.
4. **A list** (every game's journal): the beta gets a plain list that starts any questline now.

## What is built (story_quests.gd)

**Map tiers.**
- *Main line*: the gold star now sits on a soft gold glow that breathes, on the minimap and the
  full map (bigger there). It is the only mark that glows.
- *Questline starts*: a round badge in the questline's own colour (boat race blue, rave violet),
  a white ring and a bold white "!", with a slow halo. On the minimap it is pinned to the rim up to
  1.5 km away; on the full map it is twice a job icon's size with the questline's name under it.
  The legend has a "questline start" row.
- *Street jobs*: unchanged, one small icon per stand, station or depot.
- *Landmarks, metro, hospitals* (F, 2026-11-07: "they jump out too much"): no more pins and
  badges on the full map. Each is a small silhouette printed on the map in its category's colour,
  darkened, on a faint cream halo, with its name in dark ink like a paper map's own labels; fainter
  still while a quest runs. Hospitals show only while a rescue is on (F: "do we need them?").
  So the only loud marks are the main star and the "!" badges.

**Quest focus.** While anything runs (a race, a job, a ride, a rescue, the boat race, the rave, a
tow), the minimap and the full map hide the street jobs, the garage, the "?" places and the
questline badges, the kebab stands' 3D rings go, and the main star stays without its glow. The
main line's goal toast also waits (it used to pop up over the boat race's countdown).

**Starts in person.** At each start a lit column and the friend waving (one shared beacon, only
for the nearest start within 320 m). Drive within 30 m and slow below 22 km/h: the friend's card
comes up with their name and no phone ("👋 SZYMEK"), what they'd say in person, and WCHODZĘ! /
NIE TERAZ. WCHODZĘ starts the questline from where you are: Szymek takes you straight to the
pontoon's grid; Ziomek gets in and the night goes on to the meeting point and the door. Outside the
questline's hours the friend says when to come back. They greet again only after you have driven
80 m away. The old WYŚCIG ŁODZI pill by the pontoon is replaced by this.

**Calls stay.** Szymek, Ziomek and LEKTI's timers are untouched.

**The beta list.** The full map's quest card has a third tab, WĄTKI (STORIES). It lists every
questline, open ones first and nearest first, with the distance; one closed at this hour is
dimmed. A tap closes the map and the friend phones now, at any hour. Past four rows the list
scrolls.

**Starts now.**

| Questline | Friend | Start | Open |
| --- | --- | --- | --- |
| Wiślana Szprotka (boat race) | Szymek | the pontoon at Port Czerniakowski | 7:00-22:00 |
| Sekretny rave | Ziomek | his block at Osiedle Za Żelazną Bramą | Thu-Sat 19:00-4:00 |
| Nocny spot (night racing club) | Darek „Bawarka” | Plac Defilad | 21:00-4:00 |

## Adding a questline (for the padel, cinema, coffee run and night meet threads)

One block in `main.gd` `_build_stories`, nothing else in this lane changes:

```gdscript
stories.add({"id": "padel", "pl": "...", "en": "...", "who": ["Kasia", "Kasia"],
		"hello": ["„...”", "\"...\""], "closed": ["„...”", "\"...\""],
		"at": Vector2(x, z), "colour": Padel.COLOUR, "hours": Vector2(8, 22), "days": [],
		"call": padel.ring, "meet": padel.meet, "busy": padel.busy, "idle": padel.idle})
```

`call` phones now (the list's start), `meet` starts in person from the start spot, `busy` is true
while it runs (quest focus), `idle` is true when it may start (not ringing). `at` may be
`Vector2.INF` for a questline with no fixed start (list and calls only). Pick a colour no other
questline uses.

## Cost

Idle: a 0.25 s timer; the minimap and full map badges join the overlay's one triangle batch (no
new draw calls). Within 320 m of a start: one beacon (ring, column, a 7-box friend: about 10 draw
calls), never during a quest.

## Open for F (QUESTIONS)

- Ziomek's block: built at Osiedle Za Żelazną Bramą; another spot?
- The greeting radius (30 m) and speed (22 km/h): too easy to trigger by accident on Wioślarska?
- A list tap phones the friend; or should it teleport you to the start?
- Badge look on the phone: the "!" at 7 pt on the minimap.
