- Rondo de Gaulle'a as it is today: the date palm without neon on a planted island, a few deckchairs on the lawn by the de Gaulle statue, taxis waiting at their rank on the brick inner road, the plaza's five-lantern lamps, and people at the Party House café tables (some with dogs) and at every zebra.
- Round the rondo: Vitkac with rounded granite corners and glass ribbons, BGK's roof sign, and BANK PEPEO and ŻUBR on the Party House.
- Stadion Narodowy at night: lamps on the mast tips, a line of light under the roof, warm light on every step of the stairs with glowing handrails, lamps every 10 m along the curved paths, and the Arka entrance at the end of its sunken road with a tall white-rimmed arch and lit doors.
- Most Poniatowskiego's towers are floodlit at night.
- In the rain everyone walks under an umbrella; Pasaż Wiecha has people out in the evening; the app taxi and the city taxi drive newer cars.
- Wide, shallow camera views no longer show a blue strip at the bottom.

## Backlog
- fixed: the stadium's lit stairs never drew (the landmarks got no stairs data), so the flights were dark
- fixed: a wide, shallow free-camera view showed the sky's colour under the frame (the nearest ground fell behind the near plane)
- found: Experimental takes on the Mac sometimes stall on the start camera (Movie Maker repeats one frame); --skip=8 and a fresh restart help, tools/clip.sh now fails such a take
- found: the Nowy Świat / Smolna zebra by the palm sits in a darker junction patch with a pavement wedge on one side (needs the road design pass on that corner)
- found: the curved Solec 24 slab (Muzeum Azji i Pacyfiku) has no building colour in OSM, so it is generic grey-blue by day; real walls are white (needs a colour override in the bake)
- found: a Promo Mode COPY whose focus is over water drops the car in the river; pass --at= to a road
- found: the grass slope round the Arka is bare (no shrub rows); the kiosk beside the stairs is a plain box
- found: the full trailer still waits on its Mac re-render (draft PRs #640/#655)

## Roadmap
- ticked: "Stadium night lighting"
- added: "Social teasers (Reels) and the synthwave logo"
