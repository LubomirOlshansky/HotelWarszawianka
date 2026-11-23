- Android phones with a Mali or PowerVR graphics chip (Motorola, many Xiaomi and Oppo phones) now start on Medium graphics, and on any phone Auto drops one level after a session that struggled, then comes back after three smooth sessions.
- The loading screen's bar is now the Syrenka, Warsaw's mermaid, filling with gold from her tail to her sword as the city loads.

## Backlog
- fixed: Auto kept a weak Android at High (PostHog fps_sample, 19-22 Nov: Motorola edge 40 27.2 fps at High on build 14, which has #936; the Nothing Phone's 16.7 and the OnePlus CPH2415's 28.3 at a manual Ultra were the old build 13, before #936). Android by GPU (tiers.gd android_level: Adreno 7xx, Xclipse, Immortalis High; Mali, PowerVR Medium; old Adreno Low) and Auto's level steps down one after a session with over 25 % of 180 s heavy (over 25 % of refreshes missed, about 45 fps, CPU or GPU; 10 % at first stepped the Samsung A56 down at 55 fps), back up after 3 calm sessions (quality_keep.gd, settings.gd auto_drop / auto_calm)
- fixed: PostHog's app_build said "0.1" for every build; the export scripts now write data/build_stamp.json (the iOS build number or Android version code, the commit; gitignored) and app_build reads "0.1 (14, 839dfd2)"
- found: Play's build 14 (2026-11-21, main 839dfd27) has #936 but not #996 (merged 23:00 UTC that day): the new levels and Low's 30 fps cap reach Android players with build 15
- fixed: the loading bar is the Syrenka (F 2026-11-23, "the Syrenka, not the PKiN"; loading_syrenka.gd)
