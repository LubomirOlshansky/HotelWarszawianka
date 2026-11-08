# 11 Listopad (Independence Day) event: plan

Status: IMPLEMENTED 2026-11-07 on F's ask (event_day.gd, without the trailer); this file is the plan it followed. Differences: Złota 44 is lit white-to-red like F's photo, Stadion Narodowy is lit too (F's ask), the crowd runs along the whole of Al. Jerozolimskie to Rondo de Gaulle'a (the palm in F's photo 1 stands at Rondo de Gaulle'a, not Rondo Dmowskiego).
Today is Saturday 2026-11-07. **11 November 2026 is a Wednesday, four days away.** See section 8 for what that means.

## 0. The idea in one paragraph

On 11 November the game turns into "the city celebrates": around Rondo Dmowskiego the streets are full of people with white-red flags, the roads into the rondo are shut with grey police barriers, so the car cannot get in and only the helicopter can fly over the crowd; the Palace of Culture and one more tower glow white and red; at dusk a soft red haze rises over the crowd. It is the real Warsaw of that afternoon, shown the way the game shows everything else: affectionate, colour-only, nothing political.

## 1. Tone rules (decided up front, so nobody has to improvise later)

- The crowd is **colours and flags only**: white-red flags, scarves, kids on shoulders, scouts, veterans, families, brass band. No banners with words, no slogans, no group, party or organiser names, no logos, no chants (city_sounds `chant` kind is NOT used here; use a warm crowd murmur, drums, a brass band).
- The game never says who marches or why beyond "11 listopada, Narodowe Święto Niepodległości". Real life is more contested than a game should try to be; we show the shared part: the flags, the city, the evening.
- Red glow: hand-held "smoke" stays the fans.gd model (soft, no fire props in anyone's hand, no weapons). The haze comes from glow pots and light, not from figures holding burning things. A Settings toggle "Dym i race: wł/wył" (smoke and glow on/off) is the accessibility and age-rating safety valve; default ON in the world, OFF in the trailer if F prefers.
- Brands stay parodies: the billboards in F's photos (a sausage brand, a car brand, shoe and fashion chains) become our parody boards, as everywhere else in the game.
- Official layer for balance: the state ceremony at Plac Piłsudskiego / Grób Nieznanego Żołnierza (honour guard, wreaths; already a KP site in the game) gets a small ambient pass: guard figures, flags on the colonnade, a bugle at noon.

## 2. Research: what 11 listopada looks like in Warsaw

Facts below come from the sources in section 9. The one PIK road guide I read is dated for 2025 (a Tuesday); **2026 closures are unpublished as of today**, so treat these as the usual pattern and re-check ZDM/ZTM on 9-10 Nov.

- Morning to noon: state ceremonies at Plac Piłsudskiego (Grób Nieznanego Żołnierza), flags on public buildings and balconies, wreath-laying; the Presidential events are not in scope for the game.
- Afternoon: a large procession gathers at **Rondo Dmowskiego** (reported 14:00-19:00 in recent years) and walks east along **Al. Jerozolimskie**, over **Most Poniatowskiego**, to PGE Narodowy. Crowd on F's photos: dense from the rondo to the bridge, flags everywhere.
- Closures seen in recent years: Marszałkowska shut from Żurawia to Świętokrzyska before the start; Al. Jerozolimskie shut from Emilii Plater to the rondo and onward towards Praga; Most Poniatowskiego fully closed from 10:00; Wybrzeże Szczecińskie closed Świętokrzyski-Poniatowskiego; tram traffic suspended on Marszałkowska and Jerozolimskie; buses rerouted; metro runs more often (M1 about every 4 min, M2 about every 5).
- Same afternoon, a second, separate gathering in recent years at Plac Unii Lubelskiej going along Marszałkowska to Plac Trzech Krzyży. Out of scope; only the barrier idea matters.
- Light: sunset in Warsaw on 11 Nov is about 15:45, so the whole event runs from afternoon into dusk. That is exactly why F's photos look as they do: grey-blue sky, the Palace as a silhouette, red glow low in the crowd.
- Palace illumination: it has a programmable (DMX) LED rig and has been lit white-and-red for national days and anniversaries (see links). Natural for the game.
- What F's four photos give the game (in /mnt/project-files/events/refs/):
  1. Palm at the rondo (our "Pozdrowienia z Alej Jerozolimskich" palm) in a sea of flags, red glow lighting the Ministry-style façade windows: the **glow lights the façades, not just the street**.
  2. Dusk, Palace and the Zlota/Warsaw skyline over a red-lit haze, street lamps poking through: **haze layer starts at about lamp-post height (8-10 m)**, skyline stays readable above it. This is the hero image for the trailer.
  3. Midday, wide crowd, autumn trees, flags as a texture of white and red dots, the Palace behind the park: **flag density and the white-red pixel read from far away**.
  4. Heavy fog: Palace almost gone, only the spire and the clock out of the haze: **the weather-fog look; our `weather.gd` fog can carry it**.
  These are agency photos (copyright held by the agency): references for the eye only, never in the game, the site, the trailer or a repo.

## 3. How the day event switches on

### 3.1 The gate
- `EventDay` (new small node, `game/scripts/event_day.gd`) answers one question: is it 11 November? Same pattern as `districts.gd today()` and `eggs.gd` (`Time.get_date_dict_from_system()`), plus a test flag `--event-day=niepodleglosc` parsed in `main.gd` and noted in the archive flags table (so we can film and test on any date), plus a Settings line "Wydarzenie dnia" to turn it off.
- **Phases**, on the game clock (the game clock may differ from the real clock; the date is the real date, the hours are the game's): MORNING 08-12 calm, flags only, barriers going up (the build-up is part of the show); PROCESSION 13-18 crowd at full strength; DUSK 15:30-19:00 haze and glow; AFTER 19-22 crowd thins, barriers stay, Palace stays lit until 23:00. `phase_at(hour)` like `fans.gd`.
- Outside the date the node does nothing and costs nothing (not built).

### 3.2 Crowd density at the rondo
- **Reuse `crowds.gd`**: figures are already MultiMesh instances per 512 m sector cell, rewritten only when a cell's count changes. Add one more crowd site kind `rally` in `crowds.gd` (like the queues and the platform crowds): a polygon around Rondo Dmowskiego and the Jerozolimskie stretch to Nowy Swiat (about 350 m x 120 m), figures standing on the roads and pavements, facing east, density curve by phase.
- Flags: one more MultiMesh of a flag quad on a pole (white over red), swayed in the vertex shader (no CPU). About one flag per two figures.
- Budget: 1,500 figures on the iPhone 16, 800 on the iPhone 11 (same MultiMesh, instance count by quality tier, `tiers.gd`). Heli-height LOD: beyond 120 m the figures become coloured dots in the same MultiMesh (no new draw call).
- A few walking groups (reuse `pedestrians.gd` / `ped_zones.gd` walkers) streaming into the rondo from the metro exits (already built, PR #522) in the hour before: a living arrival, not a static fill.

### 3.3 Barriers: the car cannot get in, the helicopter can
- **Reuse `edge_roadworks.gd`**: it already builds a barrier line across a road, one box collider per closure, plus `lane_graph.gd` `e_shut` / `e_open` so traffic stops at the same line. For the event: a new closure set at the four arms of the rondo (Marszałkowska N and S, Al. Jerozolimskie E and W), 60-90 m out from the centre, built when the phase starts, removed in the morning after.
- Look: grey steel "barierki" (the interlocking police crowd barriers), a few white-red tape lines, two police vans nose to nose with blue lights (reuse `police` car model, lights from `club`/police rigs), cones. NOT the red-white roadworks look: that would read as "roadworks" and our edge closures already use it.
- Rules: the player's car stops at the line like at the map edge. If the car is already inside the ring when the event switches on, it is moved (smoothly, with a toast) to the nearest outside point (reuse `stop_assist.gd` / the rescue "unstuck" button logic). Traffic AI, buses and **trams are held at the ring**: `trams.gd` rerouted or paused on Marszałkowska / Jerozolimskie like the real suspension; line 22 and the two bus lines named in the PIK guide simply do not spawn.
- **Heli passes over**: the ring has colliders only up to car height (e.g. 4 m), so `heli.gd` flies over; verify the helicopter's minimum flying altitude and that nothing in the ring pulls the heli down.
- Quests and jobs whose ring or pickup lies inside the cordon are hidden for the day (a `blocked_by_event(pos)` check in `missions.gd` / `quest_lines.gd`), with the line "Dziś nie przejedziesz: święto. Spróbuj z góry." The Palace/KP quests become heli-only for the day (a gift: a unique day mission).

### 3.4 White-and-red light on the Palace and a second building
- **Reuse the Level 26 band trick** (`crowds.gd`: one mesh in `Models.material()` with `LIT_SIGN`, +1 draw call, hidden by day and when far): a band per tier on the Palace (the stepped tiers alternate: upper tier white, lower tier red, the spire white, like a flag laid on the tower), built from the same roof/outline grid. Cost: +1-2 draw calls, only at night/dusk and in range, no real lights.
- Second building (F: "another building with this light, like the lit tower in your photos"): **default: Zlota 44** (the glass sail, rebuilt in PR #321, it sits in the skyline of photos 2-4). Alternatives: Varso (the tallest, 230 m, tower in photo 4), Warsaw Spire (PR #478). F picks; the same band routine takes any tower with a roof ring. Zlota 44 gets a vertical white / red split (two vertical bands), fitting its curved glass.
- Optional pass 2: flags on the Palace colonnade and the Hotel Metropol-style tower, the Rotunda lit, red glow from the street reflected on the Rondo 1 façades (one extra glow decal per façade).
- Sky: at DUSK, `time_of_day.gd` stays on its normal curve, plus a warm low fog tint over the rondo only (see 3.5).

### 3.5 Smoke and flare glow, tasteful
- **Reuse `glow.gdshader` / `Models.glow_material()`** (additive, used for the rave beams and the road lamp halos): about 30-60 red-white glow pots in the crowd, each a soft additive blob that flickers slowly (one MultiMesh, one draw call).
- The haze: one MultiMesh of 40-80 large soft billboards (alpha, low-poly quads with a noise texture, 8-10 m up, drifting), hue pink-red near the pots and grey-white higher up; at most 2 layers of overdraw in the screen centre (overdraw is the iPhone 11's cost, not triangles). `weather.gd` fog density gets a small bump near the rondo at DUSK (photo 4's look), not city-wide.
- Façade glow: the red pots add a red wash to the façades next to them through a warm additive decal strip at 6-12 m on 4-6 façades (photo 1). One MultiMesh again.
- **Never**: figures with burning props, explosions, sparks hitting people, any harm; crash_fx stays as is. A Settings toggle for the whole smoke layer (off = flags and lights only). Safe for the stores: wording "Dym" / "haze", no "racowisko".
- Sound: warm crowd murmur loop at the rondo (city_sounds `crowd` kind extended), a brass band at the procession, bells at noon; no chants, no recorded real marches. The anthem is public domain as a melody but not as a recording: we play only our own version, short, at noon at the Tomb (honour guard), through `radio.gd`'s jingle path as a KEBAB FM station ident if F wants it.

## 4. What it reuses (summary table)

| Piece | Reuses | New |
| --- | --- | --- |
| Date gate, test flag | `districts.gd`/`eggs.gd` today(), `fans.gd` phases, `main.gd` flags | `event_day.gd` (small) |
| Crowd | `crowds.gd` sector MultiMeshes, `tiers.gd`, `pedestrians.gd`, metro exits | `rally` site, flag MultiMesh |
| Barriers, vans | `edge_roadworks.gd` closure + collider, `lane_graph.gd` `e_shut`, `police` models | barrier mesh form, closure set |
| Trams, buses | `trams.gd`, `buses.gd` line suspension | event suspension list |
| Palace + tower light | Level 26 band (`crowds.gd`), `Models.LIT_SIGN`, landmarks.gd Palace / Zlota 44 | 2-3 band meshes |
| Glow, haze | `glow.gdshader`, `weather.gd` fog, rave beams | haze billboards, pots |
| Heli | `heli.gd`, `fotka.gd` photo mode, `camera_shots.gd` | heli-only quests for the day |
| Lines, stamp | `data/dialogue.json` tags, `egg_book.gd` (a notebook stamp "11.11"), `wallet.gd`, `quest_lines.gd` | 15-20 lines, one egg |
| Add-ons check | | **Beehave: not used** (no new agent behaviour beyond walkers); **Dialogue Manager: not used** (ambient lines only) |

## 5. Performance budget (a gate)

- Target: +6 draw calls at most (crowd cells already counted, flags +1, haze +1, glow +1, bands +2, barriers +1), 0 real lights (Mobile renderer; all light is additive meshes), +1,500 instances on the iPhone 16 and +800 on the iPhone 11, transparent overdraw capped at 2 layers.
- Bench before and after with `godot --path . --disable-vsync -- --bench --nosave --event-day=niepodleglosc`, at three spots: the rondo from the car camera, from the heli at 120 m, and the Palace skyline from the north. Report the numbers in the PR; the iPhone 16 is the bench device (the iPhone 11 has no trusted certificate yet), the iPhone 11 is a "name what only the phone can show" item.
- Both city paths (runtime and prebuilt sectors) tested; the event is built after the sectors, so it does not touch derived map files.
- Fall-back: if the iPhone 11 cannot hold 60 fps, drop to flags + haze only (tier), keep the lights.

## 6. Where it fits the queue

Order, after the merge train and the iPhone 16 test (NO NEW TASKS rule):
1. **E1 gate + barriers + trams** (small, mostly reuse of edge_roadworks): Sonnet applying this spec; Opus review for the colliders and the traffic closure (gameplay).
2. **E2 crowd + flags**: Opus (performance), one MultiMesh site.
3. **E3 light: Palace and Zlota 44 bands**: Sonnet.
4. **E4 haze, glow, sound**: Opus (overdraw), then F's look check on the phone.
5. **E5 heli-only day missions, the notebook stamp, lines**: Sonnet.
6. **E6 trailer rig** (camera shots, scripted flight, a `--event-day` shots set in `tools/shots.sh`): Sonnet.
Each PR ticks its line in ROADMAP "v1.0 checklist" and adds ONE plain line to CHANGELOG for the visible change. Merge slots as usual, one PR at a time.
Light vs full definition of done: E1-E4 are FULL (verify, shots, bench, `--ios`); E5-E6 light.

## 7. Short marketing trailer: shots and storyboard

Format: 40-45 s, 16:9 master for the site and the store, 9:16 and 1:1 crops from the same takes. No voice-over, no text claims beyond the title cards (PL with EN subtitle). Music: only our own track (MUSIC.md), no recordings of the anthem or marches. Capture: game running with `--event-day=niepodleglosc`, phone-size shots with `tools/shots.sh`, flights scripted through `camera_shots.gd`, screen-record on the iPhone 16 for the "it is a real phone game" shot.

| # | Time | Shot | Camera | What happens |
| --- | --- | --- | --- | --- |
| 1 | 0-3 s | Black, then the Palace, still, grey-blue dusk sky | Static wide from the north, the skyline | Title card "11 LISTOPADA" fades in; the Palace and Zlota 44 turn white and red, one tier at a time (the light bands switch on) |
| 2 | 3-8 s | Rondo from the heli, high | Slow descent towards the palm, flags all over | Crowd murmur rises; flags sway; the flag-pole texture reads as white-red dots (photo 3) |
| 3 | 8-12 s | The barriers | Car camera from outside the ring, low, 90 degrees | The car pulls up to the grey barriers and stops; a police van's blue light; a kid waves a flag across the line; toast "Dziś nie przejedziesz" |
| 4 | 12-17 s | Switch to the heli | Cut on the car: the heli lifts off the car's roof (the vehicle switch) | The heli rises over the barrier; the camera follows, the crowd opens below |
| 5 | 17-25 s | Over the crowd | Heli low pass along Al. Jerozolimskie, 25 m up, toward the Wisla | Flags, a brass band, the palm; the first glow pots; the sky goes pink |
| 6 | 25-31 s | The haze (hero shot, photo 2) | Heli climbs, the camera pulls back and up | The haze fills the rondo, the Palace and Zlota 44 white-red above it; lamps through the mist |
| 7 | 31-36 s | Detail | Phone-size close: a toast, the notebook stamp "11.11", the radio ident "87,3 KEBAB FM" | The one joke: the parody billboard says something affectionate and silly |
| 8 | 36-42 s | The real phone | Screen recording on the iPhone 16, thumbs on the controls | Same flight, shown on the device (proves it runs on a phone) |
| 9 | 42-45 s | End card | Black, logo | "Around Warsaw · za darmo · aroundwarsaw.app", TestFlight / Play links |

Alternates: a 15 s cut (shots 1, 2, 6, 9), and a 6 s teaser (shot 6 only, a tight loop for stories). Safe-area note for 9:16: keep the Palace and the title inside the middle 70 percent.

Shoot plan: take the shots at game-clock 15:30-17:00 for the dusk, and 13:30 for the day wide; film two days before the real date (any date works with the flag), keep the real date for posting on the day.

## 8. Timeline reality and the decision for F

The date is four days away and the queue is frozen until merges and the iPhone test are done. A full event by Wednesday is not realistic with the performance gates. Options:
- **A (recommended): minimal for 2026, full for 2027.** After the freeze lifts, a small PR "E1 + E3": date gate + barriers + Palace and Zlota 44 lit; the crowd comes in a second PR. Film the trailer with `--event-day=niepodleglosc` as soon as E2-E4 exist, any date; post it on or around 11 listopada.
- **B: only the trailer rig on 2026-11-11 from main**, the barriers and light as a "look only" scene built for shots (not a shipped feature), the real feature next year.
- **C: skip 2026**, build properly, ship for the next 11 November (and reuse for 3 Maja / 1 Sierpnia / New Year).
The plan is the same in each case; only the schedule moves.

Open questions for F (I will take the defaults if not answered): second building = Zlota 44 or Varso; smoke default on or off; trailer with the anthem melody (our own version) or no music from the anthem; Settings toggle name.

## 9. Reference photos and sources (links, not copies)

Licences: the four photos F attached are agency material (Agencja Wyborcza.pl / Gazeta Wyborcza): reference only, copied to `refs/` for F, never for the game or the trailer. Commons was unreachable from this cloud session (the egress proxy blocks it), so the licence-clean searches below must be run on the Mac. Nothing was downloaded from the sites below.

- Programme and closures: [IPN, 11 November in Warsaw](https://ipn.gov.pl/pl/aktualnosci/209268,Obchody-Narodowego-Swieta-Niepodleglosci-Warszawa-11-listopada-2024.pdf) · [PIK Warszawa, road guide](https://pik.warszawa.pl/press-room/11-listopada-w-warszawie-informator-drogowy/) · [Interia motoryzacja, closures](https://motoryzacja.interia.pl/wiadomosci/news-11-listopada-omijaj-centrum-warszawy-zamkniete-ulice-i-zmian,nId,22452784) · [Eska, 11.11.2026 events](https://www.eska.pl/news/11-listopada-2026-gdzie-jechac-w-tych-miastach-organizowane-sa-uroczystosci-aa-Sre3-nbXv-nRNP.html) · [Autocentrum, traffic](https://www.autocentrum.pl/newsy/swieto-niepodleglosci-czyli-duze-utrudnienia-w-ruchu/)
- The rondo and the barriers (the day before is the barrier reference): [Wprost gallery, Rondo Dmowskiego the day before](https://www.wprost.pl/galeria/20249/rondo-dmowskiego-na-dzien-przed-swietem-niepodleglosci.html) · [Forsal, march starts at the rondo](https://forsal.pl/gospodarka/polityka/artykuly/9347491,marsz-niepodleglosci-wyruszyl-z-ronda-dmowskiego.html) · [Gazeta Prawna gallery](https://www.gazetaprawna.pl/wiadomosci/kraj/galeria/9347445,marsz-niepodleglosci-przeszedl-ulicami-stolicy-galeria.html) · [Wprost 2019 photo report](https://www.wprost.pl/polityka/10268951/marsz-niepodleglosci-2019-w-warszawie-fotorelacja.html)
- Crowd and flags, archive photos (PAP, licensed for editorial use, links only): [dzieje.pl PAP node 17892](https://dzieje.pl/node/17892) · [node 11734](https://dzieje.pl/node/11734) · [node 110279](https://dzieje.pl/node/110279)
- Palace and buildings lit white-red: [Reform.news, Palace lit white-red-white](https://reform.news/en/palace-of-culture-and-science-in-warsaw-illuminated-in-white-red-white-colors) · [Live Design, Palace DMX rig](https://www.livedesignonline.com/w-dmx-tm-helps-illuminate-warsaw-s-palace-culture) · [Wprost, iconic buildings lit white-red](https://www.wprost.pl/10167816) · [TVN24, flag colours on buildings](https://tvn24.pl/tvn24-news-in-english/polish-flag-colour-displayed-on-buildings-in-many-world-cities-ra882971-ls2413226) · [pkin.pl illumination](https://pkin.pl/?p=12184)
- Background (neutral overview): [Wikipedia, Independence March (Poland)](https://wiki.riteme.site/wiki/Independence_March_(Poland))
- **To run on the Mac (free licences, downloadable)**: Wikimedia Commons searches "Rondo Dmowskiego", "Marsz Niepodległości Warszawa", "Pałac Kultury iluminacja"; **Mapillary** street-level frames of Rondo Dmowskiego and Al. Jerozolimskie (CC BY-SA; the cloud has the token, the Mac does not) for the barrier and lamp-post forms. The Codex download recipe from project memory works for the Commons set (run from the target folder in `/Users/mac/Documents`).
- Best of the free set for the game is still **a day-before walk on 10 Nov at the rondo with a phone**: how the barriers are laid, the vans, the stage rigs. I can write the 12-shot checklist for that walk.

## 10. Risks

- Political reading: keep to section 1; no organiser, slogan or sign-off from the game; F gives the final yes on every shot of the trailer.
- Store review: haze and glow pots read as "smoke effects"; the toggle and the neutral wording cover it. Age rating: confirm no change (no real pyrotechnics on figures).
- Performance: overdraw from the haze on the iPhone 11 (section 5 fallback).
- Cordon vs quests: a stuck player. Mitigation: the move-out on switch-on and the unstuck button.
- Real date drift: the real programme may differ in 2026; the game follows the pattern, not the exact times, and says nothing about route claims.
