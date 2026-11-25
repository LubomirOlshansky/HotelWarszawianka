- At THE TAPCZAN an empty wallet still gets you the first beer of a visit on the house, with a word from the barman, and Pani Gienia's "first time" is now a game you can win.

## Backlog
- fixed: PT-56, Pani Gienia ran the table in one turn after her re-rack: her late skill 0.95 → 0.73 (coordinator's call, F can change it), balls back unchanged; check_tapczan's reference bot (a decent player, 400 seeded games) wins 36 % against her (was 5 %), held at 30-40 % by a new check row; the sommelier 25 % and the open-space crew 63 % unchanged
- fixed: a 0 zł player was refused at the bar (P22): the phase-2 draft poured a broke player's first pint free, the tap list rewrite replaced `order` and dropped it; now the visit's first glass is on the house (three barman lines), the second refused, the bar still stops at four, the wallet never below 0 (check_tapczan row)
- found: Pani Gienia is now easier than the sommelier for a decent player while her stake (150 zł) is the highest; the feel test on the phone decides (PHONE-CHECK 15zzk)
- (CHANGELOG and BACKLOG were edited directly in this pull request because the task asked for it; the fold should drop this note's duplicate lines)

## Roadmap
- ticked: "THE TAPCZAN phase 2" PT-56 and the first pint on the house
