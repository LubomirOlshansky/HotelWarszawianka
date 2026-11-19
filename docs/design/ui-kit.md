# The UI kit: one look for every screen

F, 2026-11-19: "work on the colors of interface to be same, maybe add some design system to make
the game feel like one game, no different elements, one style." Visual sheet with the audit and
the before/after mocks: https://claude.ai/artifact/NgjMk7bJM4KyWhVkRQHWnq

The kit is `game/scripts/ui_kit.gd`. The ratchet is `tools/check_ui_kit.py` (verify step
`uikit`). The owner row is in `docs/architecture/extending.md`.

## 1. What was there (main 7b2e972, 2026-11-19)

Most screens already used one recipe: the settings card (hud.gd `_panel_box`, loop 2e). It was a
near-black violet card at 94 %, a thin light edge, cream text and a gold accent. Eight scripts
kept their own copy of those colours, though, and the edges had drifted:

- 129 different hex colours across 11 UI scripts, with two golds (`#ffd23f` and `#f0b429`) and
  three reds (`#ff4f6d`, `#ff5a5a` and `#ff3b3b`).
- Ten corner sizes, from 3 to 20 pt.
- The garage title was blue. The quests screen marked a chosen row in crimson on one tab and in
  gold on the next. "CALL MATI" was a red outline, which elsewhere means quit.
- The end card's title was in sentence case while Settings used capitals, and its only button
  was a ghost outline.
- The title screen had cyan, square-cornered buttons of its own.
- The HUD's pills, chips and call view each drew their own box.

## 2. The tokens

| Token | Value | Job |
| --- | --- | --- |
| `CARD` | `#120f1a` at 94 % | every card and panel |
| `RAISED` | `#1e1a28` | buttons, rows and tiles inside a card |
| `GLASS` | `#120f1a` at 34 %, edge white 42 % | only controls over the road (pedals, steering, map zoom) |
| `EDGE` / `EDGE_STRONG` | white 16 % / 30 % | a card's or button's border; strong on hover |
| `INK` | `#fbf7ee` | main text |
| `SUB` | `#c9c2d8` | second lines and descriptions |
| `FAINT` | `#8e879e` | keys in a key/value list, disabled |
| `GOLD` | `#ffd23f` | the one gold: main buttons, chosen tabs, toggles and rows, card titles, labels |
| `GOLD_TINT` | gold at 22 % | the fill under a gold edge (chosen) |
| `ON_GOLD` | `#1a1622` | text on a gold fill |
| `ALERT` | `#ff4f6d` | NEW, quit, wrong way, a rescue |
| `GO` | `#5fd38a` | won, delivered, safe, hidden |
| `POLICE` | `#3d7bff` | police and the chase |
| `HEAT` | `#ffb020` | timers, hot food |
| `NEON_PINK` | `#ff4fd8` | brand: KEBAB FM, stars and respect, portrait rings, the title's glow |
| `NEON_CYAN` | `#5fd4ff` | brand: the title's lines, photo mode's frame, sliders |

The type sizes, in points, are `T_BANNER` 44, `T_CLOCK` 22, `T_TITLE` 17, `T_BODY` 15,
`T_SUB` 13 and `T_LABEL` 11. These are hud.gd's scale from loop 2e, now named in the kit.

There are three corner sizes: `R_SMALL` 6 for chips, tiles and rows, `R_CARD` 12 for cards and
buttons, and a pill for round things. Spacing steps are 4, 8, 12, 16 and 24 pt. A card's padding
is 12, and a touch target is at least 44 pt.

## 3. Rules

1. Gold means you can press this or this is chosen. It is never a decoration.
2. Meaning colours (`ALERT`, `GO`, `POLICE`, `HEAT`) appear only when the colour says something.
   The neon pair is the brand and is never a button.
3. Button kinds:
   - PRIMARY: a gold fill with `ON_GOLD` words. At most one per card, for the main action.
   - SECONDARY: `RAISED` with `EDGE`.
   - SELECTED: `GOLD_TINT` under a gold edge, for tabs, toggles and chosen rows.
   - DANGER: `ALERT` words and edge, for quit and give up.
4. Button words are in capitals. Card and screen titles are gold capitals at `T_TITLE`. Item names
   (a quest or a paint) are ink at `T_BODY` in normal case. Labels over a group are gold capitals
   at `T_LABEL`.
5. The game uses one UI font, today's default. The slanted heavy cut is only for the logo and big
   banners.
6. The 3D city, neon signs, map art and pin colours are not the kit's concern. It covers only the
   interface on top.

## 4. In code

- Read a token as a constant (`UiKit.GOLD`).
- Make a style with a builder: `card`, `row`, `chip`, `pill`, `glass`, `button_boxes` or
  `style_button(b, Kind.PRIMARY, pt)`.
- Dress a label with `style_label(l, "title", pt)`.
- `UiKit.theme(pt)` builds a Godot Theme from the same tokens for the root window, so a plain
  Button is already a SECONDARY kit button.
- A script may keep a local alias (`const INK := UiKit.INK`) so its code reads short.
- A new colour that is not a token means the kit is missing one. Add it to `ui_kit.gd` and to the
  table above in the same PR.

## 5. Rollout

| Step | What | State |
| --- | --- | --- |
| 1 | `ui_kit.gd`, the ratchet. hud.gd, settings, notebook, photo mode, bubbles, quests and the map alias their copies to the kit (same values, no visible change) | this PR |
| 1b | The Theme on the root window; settings, notebook, photo mode and bubbles drawn with the builders | after F's OK of the sheet |
| 2 | The HUD: pills, chips, call view, challenge card, job card, toasts | |
| 3 | Map and quests: one gold and one red, the chosen row gold on every tab, the legend (after #949) | |
| 4 | Garage, end card, title buttons, club and the police balloon | |

F decided on 2026-11-19 that the plates over the full map use the dark card too, the legend
included, so there is no paper variant.
