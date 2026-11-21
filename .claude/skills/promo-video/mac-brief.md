# Brief for the Mac session (Remote Control), template

Copy, fill the <>, send as ONE message. Numbered steps, exact commands, what to report. The Mac
session takes F's words from the thread only; it makes no commits.

```
Work in the worktree <NocnaWarszawa-xxx> (branch <branch>). Every game run passes --nosave and quits,
and every godot command has --path game. One Mac user at a time: do not touch other threads'
worktrees or Xcode, do not kill godot processes that are not yours. No commits.

STEP 1 BEFORE (first, on the worktree as it is, do not fetch yet): stills, one camera per run:
  godot --path game --resolution 1080x1920 -- --nosave --prebuilt --sectors=all --quality=ultra
    --governor=off --nohud --game-clock --date=<YYYYMMDD> --clock=<HH:MM> --at=<X,Z on a road>
    --shots=40 --out=~/Documents/aroundwarsaw-teaser/<piece>/before --cams="name:x,y,z,yaw,pitch,size"
STEP 2 UPDATE: git fetch origin <branch>; fast-forward to <sha>; godot --headless --path game --import --quit;
  python3 -I tools/bake_sectors.py; godot --path game --resolution 320x180 --script res://tools/bake_city.gd
  (with a renderer, never --headless).
STEP 3 AFTER: the same stills into .../after, then tools/promo_sheet.sh before after. Send the sheets
  as soon as they exist, before the clips.
STEP 4 TAKES: tools/promo_batch.sh docs/promo/<piece>.takes (sizes, flags in the manifest). Look at each
  NAME-sheet.png; re-shoot what is wrong (streaming holes, grey proxies, car in the river, top-down view).
STEP 5 REPORT: file paths, the commands that worked, anything that looked wrong.
```

If F reorders mid-run, send "new order: finish step N, then step M" to the same session.
