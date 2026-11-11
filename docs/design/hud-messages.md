# The message director: what the HUD says, when, and where

F (2026-11-11, with a screenshot of the night race): "the game starts to be overloaded and the user
does not see the game ... during missions limit the messages, do not show the radio messages, the
player is concentrated on the chase and can't read them; make the active quest view more organised
and compact; hide the ride app during quests; partners' messages should not make it hard to see
what is in front; racers like Pani Halina approach and the player does not see the start-race
button: make it a call to action, not text at the bottom." And: "also the incoming calls in this
queue, with logic too."

The screenshot (a race to the car park under the stadium, with the police after the car) had six
texts up at once over the road: the radio's news (KEBAB FM, a fender bender on Aleje), the
app-taxi's GPS joke (Podwózka), the race card (two-line title, the metres, the hint and an empty
English line), the police pill, the partner's bubble (Darek „Bawarka") and the TYGRAM pin. None of
them knew about the others: each script decided on its own that its line mattered.

## 1. What talks today (the inventory)

About fifty scripts put text on screen through seven channels:

| Channel | Where (hud.gd or bubbles.gd) | Who uses it | Spot on screen |
| --- | --- | --- | --- |
| Speech bubbles | `bubbles.say`, `dialogue.say`, `say_reaction`, `say_ambient` | quests and partners, police and guards, rivals, crowds, buses, fans, packs, loud cars, crash scenes, GPS moments, eggs (≈30 scripts) | over the speaker, kept off the HUD |
| Radio ticker | `hud.ticker` from radio.gd (`announce`) | the host (dialogue.gd), crash scenes, crazy drivers, loud cars, EV tow, police radio, rave password, track and station captions | bottom left |
| Toasts | `hud.toast`, `hud.ambient_toast` | every quest's feedback (≈150 calls), flavour (packs, fans, wellness, city life) | bottom centre |
| Notes and info cards | `hud.show_note`, `hud.show_info` | easter eggs, notebook, districts, syrenki, cassettes, tape, storefronts, the TYGRAM pin; a tapped landmark | right column |
| Cards | `show_card`, `show_side_card` | offers, results, calls (ODBIERZ / ODRZUĆ), story answers | top centre or right column |
| Quest status | `show_status` | every running quest, race and ride | top right |
| Prompts and alerts | `show_challenge`, `show_banner`, `police_pill`, the context button (`show_pill`) | rivals and couriers, countdowns, the police, calls, Podwózka, the tow | bottom centre, middle, top centre, top row |

The layout (hud.gd `_layout`) already keeps panels from covering each other, and the chatter budget
(chatter.gd, 2026-11-03) already caps the bubbles. What was missing is the game's state: a radio
joke is fine on a quiet drive and noise in a chase.

## 2. The director (game/scripts/messages.gd)

One small pure object, owned by the HUD (`hud.messages`), decides every line: **SHOW** now,
**DEFER** to a queue, or **DROP**. It takes the line's channel, its priority and the context.

**Contexts** (hud.gd `context_now`, worked out each frame from what the HUD shows and `quest_on`):

| Context | When |
| --- | --- |
| FREE | driving round the city |
| QUEST | a job, ride, rescue, tour or questline runs (the status card is up, or main.gd says so) |
| CHASE | the police after the car or searching, a race (the position badge), a countdown banner |
| FOCUS | a scripted moment (the drag's rev counter: `hush`) |

**Priorities**, low to high: AMBIENT (flavour toasts), RADIO (the host, the news, a new track), INFO
(easter eggs, a district found), QUEST_LINE (a quest's own message: the TYGRAM pin), ALERT (a result,
a warning, the player's own action such as a station they picked).

**The rules** (the lowest priority each channel shows at once):

| Channel | FREE | QUEST | CHASE | FOCUS | Below it |
| --- | --- | --- | --- | --- | --- |
| Radio ticker | all | INFO+ (no host, no news) | ALERT only | ALERT only | dropped (a joke is stale a minute later) |
| Toast | all | RADIO+ (no flavour) | RADIO+ | ALERT only | dropped |
| Note | all | QUEST_LINE+ | QUEST_LINE+ | ALERT only | **queued** |

**Bubbles** follow the context through the chatter budget (`chatter.context`): in QUEST no ambient
line; in CHASE and FOCUS no reaction either, and **one voice at a time** (the newest quest or police
line takes the old one's place). The app-taxi's GPS moments are now ambient (they were quest lines
and talked over races).

**The queue**: a deferred note waits (the same note once), and comes back when the context lets it
through, SETTLE (3 s) into a calm spell, then one every FLUSH_GAP (2 s), the highest priority first,
at most MAX_QUEUED (6), each for at most TTL (4 min). So an easter egg found mid-chase is told after
the chase, not lost and not on top of it.

**Toasts never wipe each other**: a new toast that comes within TOAST_GLANCE (1.6 s) of the one up
waits for it (the first fades early), at most two waiting. ALERT does not wait.

**Incoming calls** (F's follow-up): every friend's call (Ivan, Darek, Mati, Szymek, Claire, Wiktor,
the crawl, the EV tow, Mrożulo, DESKA) keeps its own timer, but asks the director before it rings:
`call_ok` is true only in FREE, CALL_SETTLE (8 s) into a calm spell (never straight after a result
or an escape) and CALL_GAP (60 s) after the last call of anyone, so two friends never ring back to
back. Wired through main.gd `_free_block` (all questline calls) and trend_job.gd (its calls); the phone
view (`show_call`) and an ODBIERZ card record the ring (`call_rang`). A call
the player asked for (the WĄTKI list, a test flag) does not ask. The rescue line (missions.gd: the first
call 60 s in, the next 90 s after one ends) asks the same gate: when its countdown runs out it waits
at zero until `call_ok`, and its ring counts as a call, so a friend never rings straight after a
rescue call and a rescue never rings in a race. A rescue the player asks for (the HELI list) does not
wait.

What else decides a call in free roam (unchanged): each friend's own timer (shisha, meet, crawl: the
first 4 to 8 min of play, the next 20 to 40 min later; EV tow 5 to 8 min, then 12 to 18; the boat race
by day 5 min in, then every 25 min; Kieślowski 10 min in, the cinema tour 8 min in, both every 30 min,
in their hours; the rave 30 to 75 s after its hint), a call not answered in 25 s becomes a missed
call, and main.gd `_free_block` (nothing else on: no card, mission, ride, job, race, club, flight).

## 3. Screen slots (where each thing lives)

| Slot | What | Rule |
| --- | --- | --- |
| Top row | gear, speed, context button, RADIO, HELI | fixed |
| Right column, top | the quest status | compact (below) |
| Right column, under it | notes, landmark cards, side cards and calls | beside the car, never over it |
| Top centre | call and offer cards, the police pill | one at a time |
| Middle | the countdown banner | only in a countdown |
| Bottom centre | **the call to action** (the race challenge), then toasts | the challenge first |
| Bottom left | the radio ticker | FREE only, or the player's own station |
| World | bubbles | off the HUD; off **the road ahead** when there is room |

**The road ahead** (hud.gd `keep_clear_rects`): driving faster than 12 km/h, three boxes run from the
car's spot along its heading (the minimap's arrow, squashed as the isometric view is), further the
faster it goes (a quarter to almost half the screen's short side). A bubble tries every spot off
those boxes first and stands on the road only when the HUD leaves it nowhere else. A partner riding
along talks beside the car, not in front of it.

## 4. The compact quest card

- 240 pt wide (was 260); the title wraps to two lines at most.
- The clock and the metres on one line, no leading gap when there is no clock.
- The English line under the hint is gone (one language at a time left it empty, a blank line).
- The hint shows for its reading time plus HINT_HOLD (3 s) when it changes, then folds away; a hint
  that only counts (metres, seconds: "Seba: 40 m za tobą" to "35 m") is the same hint and stays
  folded. Measured: 94 pt tall with the hint, 74 pt folded (the screenshot's card was about 130 pt).

## 5. The race challenge as a call to action

The old prompt was a chip at the bottom ("MRUGNIJ ŚWIATŁAMI · PANI HALINA", in the chip's normal
body size): easy to miss while a racer rolled up. Now it is a button 58 pt tall in the racer's colour
(a dark fill, a 3 pt border), a chequered flag on its left, the challenge in the title size over what
to do ("WYŚCIG · PANI HALINA" over "Mruga do ciebie! Dotknij albo L"; in English "RACE · PANI
HALINA" over "Flashing you! Tap or L to race"). It pops in (18 % larger, settling in 0.35 s) and
breathes while it is up. The same for the couriers ("WYŚCIG · PĘDZIK") and a locked racer
("ZAMKNIĘTE", with what is missing under it).

## 6. The ride app during quests

PR #646 (open when this was written) keeps PODWÓZKA off the context button while any mission, race,
job, questline or tour runs (rides.gd `mission_on`). The director adds the other half: with a quest
on, Podwózka's GPS jokes (ambient now) keep quiet too.

## 7. How to add a new message

- A bubble: pick its class (`say` for a quest, `say_reaction`, `say_ambient`); never a cooldown of
  your own.
- A toast: `hud.toast(pl, en)` for quest feedback; `hud.ambient_toast` for flavour; pass
  `Messages.ALERT` only for something the player must see at once.
- A note: `hud.show_note(title, body, colour)` waits during quests by itself; a quest's own message
  passes `Messages.QUEST_LINE`.
- A radio line: `radio.announce`; it shows in free roam only.
- A phone call: ring only when your `free_now` (main.gd `_free_block`) or `hud.call_ok()` says so.
- Tune numbers only in messages.gd (and chatter.gd for bubbles). `game/tools/check_messages.gd`
  (verify step `messages`, CI) checks the rules, the queue, the calls, F's night race replayed, the
  toast wait, the compact card, the challenge and the road ahead.

## Open questions (parked in docs/QUESTIONS.md)

- Rides (Podwózka) count as a quest, so the radio host keeps quiet during a ride. If F wants the
  radio on a ride, rides move to their own context (radio on, flavour off).
- The hint folds after a few seconds in every quest. If a quest's hint is a standing instruction F
  wants kept, that quest can pin it.
