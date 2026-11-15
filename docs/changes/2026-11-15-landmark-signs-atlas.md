- Seventeen landmark signs that never lit now glow: LEGUMINA on Legia's stadium, WEKTRA on Babka Tower, DELOJT on Q22, HOTEL EUROPEJSKI, BRISTOL, POLONIA PALACE, the river bars' names and Śródmieście's cafés; long sign words are no longer cut short.

## Backlog
- fixed: 17 landmark signs drew nothing because their word had no row in the neon atlas (`neon_signs.gd` LANDMARK_WORDS): the sign's row came back -1 and the shader read an empty edge
- fixed: the atlas was 72 px wide, so ten words (HOTEL EUROPEJSKI, POLONIA PALACE HOTEL, CHARLOTTA MENORKA, WARSZAWA GŁÓWNA, RADA SPÓŁDZIELNI ORŁÓW and others) were cut off; it is 128 px now
- found: check_mesh_quality now fails a landmark sign whose word is not in the atlas or is wider than it, so a new sign can't go dark unnoticed
- found: Torwar's hall is a street block (blk_25844922) whose brick base and cream upper match the street photos; a photo pass needs aerial or Commons photos (draft in the shared files, torwar/torwar-draft.patch)
