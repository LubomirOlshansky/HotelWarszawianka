## Backlog
- fixed: pipeline review W4 ("every landmark invents its own facade parts"): the facade kit, `game/scripts/facade_kit.gd`, with shared windows in seven styles, balconies, ledges, cornices, pilasters, columns, pediments, a portico, an attic and a roof lantern, and a palette of 33 named colours (docs/design/facade-kit.md); `landmarks.gd` extends it and its emitting core moved there unchanged
- fixed: no proof that a refactor of the landmark code changed nothing: `game/tools/site_dump.gd` writes every vertex of every site and `tools/site_parity.py` compares two dumps (bit for bit, or triangle by triangle within a tolerance)
- found: the private facade helpers still in `landmarks.gd` are listed in `tools/check_facade_kit.py` with what keeps each from the kit; each leaves the list when its landmark is next reworked, with a look check
- found: the landmarks that exist keep their own colours; taking the palette's names changes their look a little and goes landmark by landmark, with a look check

## Roadmap
- added: "Facade kit and palette (pipeline review item 4)": ticked; next is the split of `landmarks.gd` by site (item 5, tech-debt TD-10)
