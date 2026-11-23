- Settings → OGÓLNE has one PRZYWRÓĆ DOMYŚLNE button (tap twice) that puts every player setting back to its default; the language, the stats choice and the DEV switches stay.

## Backlog
- fixed: settings redesign step 5: OGÓLNE → PRZYWRÓĆ DOMYŚLNE, two taps like NOWA GRA; settings.gd `player_defaults()` gives the panel's values of a fresh file and main.gd applies each through its own `_on_setting` case. The Klasyk colours stay for now: dropping them waits on TestFlight usage of the Kolory choice
