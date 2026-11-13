## Backlog
- fixed: architecture TD-11, group 1 of 3 (the HUD, the dialogue, the bubbles): 22 private copies of a fake HUD, dialogue or bubbles in 18 checks are gone; those checks take the shared stand-ins (`game/tools/fakes.gd`), so a new argument on `hud.toast` or `dialogue.say` is changed in one place. Each moved check prints what it printed and notices the same deliberate breaks of the game's scripts as before the move
- fixed: the shared `Dialogue` and `Bubbles` had fallen behind the game (their `say` took no class and key, there was no `say_reaction`, `allows` or `muted`), which is why eight checks kept private copies that did; they take what `dialogue.gd` and `bubbles.gd` take now
- fixed: new step `fakes` (`check_fakes.gd`, CI's quick group) holds it by rule: every function a stand-in shares with the game's script takes the same arguments (read from both scripts), and a script under `game/tools` that writes its own stand-in for the HUD, the dialogue or the bubbles fails the step
- found: three private stand-ins are left on purpose (`check_police.gd` `FakeHud` and `FakeBubbles`, `check_crazy_drivers.gd` `FakeBubbles`): the racer work has those checks in hand; they are named in `check_fakes.gd` `LEFT` and move with that work's next change to them
- found: 56 private fake classes in 31 checks remain for the next groups (23 `FakeMap` and 3 `StubMap`; then radio, sounds, traffic and the rest)
- found: `hud.gd` still has `pill_free()`, which no script calls since the context button got its ranks (`pill_free_for`); `fakes.gd` has a switch of the same name

## Roadmap
- added: "Shared test stand-ins, group 1: the HUD, the dialogue, the bubbles (F, 2026-11-13, architecture plan, background item; tech-debt TD-11)": ticked, 18 checks on `fakes.gd` (verify step `fakes`)
