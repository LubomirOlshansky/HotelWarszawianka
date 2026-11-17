- The full map is clean now: the city, your car, your route, your friends' quests with their names, and one big QUESTS button.
- New QUESTS screen: first steps, friends' quests, side jobs, rivals and your collection in tabs, each with what it is, when and where, and how many you have done. SHOW ON MAP puts it on your route.
- When a friend calls, the call says which quest they are inviting you to. Turn it down and it waits in QUESTS, marked NEW.
- After your first kebab, a short card shows what else the city has (rides, races, rescues, friends' quests, the collection), with a button straight to QUESTS.
- Every quest and side job in QUESTS has its own pixel-art icon (24 new icons, drawn with Codex in the style of the portraits).

## Backlog
- fixed: F's playtest 2026-11-17, the full map was overcomplicated (the legend with counters, the title, the list and the hints covered the map; the questlines were missing in quest focus; "main line 0/0" and the metro icons meant nothing)
- fixed: F 2026-11-17, a new player did not learn early that the game has many activities
- found: the old one list's code in quest_lines.gd has no reader (tech-debt TD-29)
- fixed: CI's pause run, the map's coach mark took the ✕'s tap (its text box let no tap through)
- fixed: the screenshots, a QUESTS tab with a head line (First steps, Questlines, Rivals) opened scrolled past its picked row
- found: QUESTS reopens on its first tab each time the map opens; whether it should remember the last tab is in QUESTIONS

## Roadmap
- adds: "QUESTS screen: one icon per quest (Codex art) on the phone"
