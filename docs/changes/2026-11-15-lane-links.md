- Cars keep their lane across junctions: going straight on they no longer drift into the next lane, cars in a turn lane take its turn, and the turn arrows sit in the lanes they are for.

## Backlog
- fixed: RT-2, lane links through junctions from OSM `turn:lanes` instead of `next_lane`'s guess; arrows from the same data (`tools/lane_links.py`; `road_truth` R3 406 → 261, ratchet lowered)
- fixed: `road_truth.py` modelled the old lane rule with Python's floor division where the game truncates (403 counted, 406 true)
- found: 261 straight-on links still land over 1.75 m aside where the two edges' lanes do not line up at all (a two-way street into a one-way half, a widening on one side); no lane choice fixes them, the edges' offsets must (RT-4, RT-6)

## Roadmap
- ticked: "Roads true to life RT-2: lane links from `turn:lanes`, arrows from the same data"
- added: "Roads true to life RT-3 to RT-9: turn restrictions (after the post-demo re-stamp), lane changes as paint, roundabouts, kinks"
