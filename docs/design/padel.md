# Padel in Warsaw: lore, characters, jokes (F, 2026-11-01)

F: "there should be more about padel in the lore". Padel is the 2025-26 city sport joke: glass
walls, a ball that comes back, a booking you cannot get, a club hoodie before the first game.
Original names only, affectionate, never about real private people (CLAUDE.md "Content").

## The idea in one line
Everyone in Warsaw is "starting padel on Monday"; the courts are booked three weeks out; the
sport is mostly about the hoodie, the story from the court and finding a fourth player.

## Places
- **PADELNIA** (built, `Storefronts.TRENDY`, neon sign): the basement court. Now with a queue
  (`Crowds.padel_queue`: 14 people weekday evenings 17-23, 10 on weekend mornings 9-13, 3 at the
  desk otherwise) and eight `viral` lines tagged "padel".
- **Ściana Płaczu** (idea): a glass court on a roof, "the wall that returns everything", where
  the ball, like an old email, always comes back.
- **Pro Shop "Rakieta w Cenie"** (idea): sells racket, hoodie and a "partner finder" board.

- **WTS DESKA** (built 2026-11-02, `landmarks.gd` DESKI; parody of the real WTS DeSki at Zaruskiego 8
  by Most Łazienkowski): a closed tennis hall over four mapped pitches, one outdoor glass padel
  court (blue, lit at night, floodlights) with four players, a DESKA neon on the clubhouse. Notebook place `deski`, three padel lines about it, and a
  "Czwarty" phone call (`trend_job.gd offer_deski_call`, `--trend-job=7`): a friend rings, one of
  the four hurt a leg at pole dance, drive or fly to the gate within 8 minutes (the helicopter
  counts within 28 m). Tone: affectionate, no private people.
- **The call, reworked (2026-11-07)**: it opens like Szymek's boat race and Ziomek's rave. First
  "📞 KUBA DZWONI" with a one-line bio of the caller (`DESKI_BIOS`) and ODBIERZ / ODRZUĆ, the
  phone buzzes; only an answered call says what's wrong (BRAKUJE CZWARTEGO!, JADĘ! / NIE DZIŚ).
  On time at the court you play: **a three-point match**, one card per point with a rally
  (`RALLIES`, five, three picked per call) and three shots, LOB / ZE ŚCIANY / SMECZ. Each rally has
  one shot that wins it (the smash for a ball off the back glass, the lob over a pair at the net,
  waiting for the glass on a fast corner ball...), so a player who reads the situation wins. Each
  point won: +6 zł, +2 respect; 0-3 points give the score (2:6 1:6 ... 6:2 6:3) and the closing
  line (3/3: the club hoodie and "from Monday you're our regular fourth"). Landing the helicopter
  by the court: Pani Basia's "the helicopter parking is on the river side" and +5 respect. Late:
  no match, they played three-a-side.

## Characters (ideas, none built yet)
- **Trener Dominik**: ex-tennis, "nie biegaj, ustaw się". Appears as a padel court voice.
- **Pani Basia z recepcji**: knows who booked what, since 2024; "wolny kort jest tylko w
  poniedziałek o 6:00, ale to tylko dla mnie".
- **Prezes z Mokotowa**: bought three rackets, plays zero games, leads the club's WhatsApp group.
- **Fourth Player** ("Czwarty"): the running gag, always looking for a fourth. The poster
  "SZUKAM PARTNERA DO PADLA. DOSŁOWNIE." is his.

## Lore entries for the notebook (idea, one line each)
1. "Padel przyszedł do Warszawy z Hiszpanii, ale rezerwacja jest jak z PKP."
2. "Ściana to nie błąd w grze: ściana jest częścią gry."
3. "W Warszawie jest więcej kortów niż drużyn i więcej drużyn niż graczy."
4. "Pierwsza zasada padla: nie mów, że to tenis."

## Side quest (built: "Czwarty", `trend_job.gd`, `--trend-job=5`)
"Czwarty": a courier-style job. The Fourth Player at PADELNIA's door asks the car to fetch
three players from Powiśle, Mokotów and Praga before the booking ends in 25 min. Pay 45 zł,
tip "bluza klubowa" egg. Reuses the trend job's pickup and a three-stop route.

## Built so far
Queue at PADELNIA by hour with eight lines; lines in `dialogue.json` "viral" (tag "padel"):
wall as spam, coach, unplayed racket, tennis-padel-pickleball, three-week booking, the story
photo, fourth on court, chess with a ball.

Then: three character lines in the queue, a notebook place `padelnia` (chapter "trendy"), and the "Czwarty" job (fetch a player 400-1500 m away, bring them to the court in 7 min; 45 zł + 8 zł a km there and back, +14 respect). Offered when the car is within 60 m of PADELNIA's door and its line has 10 or more people.
