# Google Street View as a reference source

Tool: `tools/streetview_fetch.py` (Street View Static API). Key: environment secret
`GOOGLE_STREETVIEW_KEY`, never in a file, never in chat. Output: `refs/<slug>/streetview/`
(gitignored). Reference only, like every refs/ photo: not committed, shipped, traced or textured.
Google's terms limit storing and deriving from its imagery, so keep the files local and few.

## One-time setup (F)
1. console.cloud.google.com, sign in, create a project "around-warsaw-refs".
2. Billing: link a card (required even for the free tier).
3. APIs & Services > Library > "Street View Static API" > Enable.
4. APIs & Services > Credentials > Create credentials > API key. Open it, rename it
   "streetview-refs". Under API restrictions choose "Restrict key" > Street View Static API only. Save.
5. Billing > Budgets & alerts > Create budget: $1, alerts at 50% and 100%.
6. APIs & Services > Street View Static API > Quotas & system limits: set the daily
   "requests per day" cap to about 300 (edit the quota).
7. Claude environment settings > Environment variables / secrets: add `GOOGLE_STREETVIEW_KEY` with the key.

Metadata calls are free and do not use quota; each image is one billable request
(free monthly tier, then paid; check current pricing in the console).

## Use
For a whole building: `python3 -I tools/streetview_fetch.py --building="NAME in centrum.json" --slug=KEY --fov=100`
(one Google panorama per side of the outline's bounding rectangle, three aimed shots each, pitch
from the height; user photospheres and sides seen more than 45° off square are skipped; at most
16 images). For one spot: `python3 -I tools/streetview_fetch.py X Z --slug=NAME --list` (is there
coverage, which date), then without `--list` for 4 headings, or `--heading-to=LAT,LON` for one
shot aimed at a building. Where it fits in the modelling workflow: the model-from-photos skill,
section 1 (after the 3D Tiles run, before the spec).
